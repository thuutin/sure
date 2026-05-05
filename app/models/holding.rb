class Holding < ApplicationRecord
  include Monetizable, Gapfillable

  monetize :amount

  belongs_to :account
  belongs_to :security

  validates :qty, :currency, :date, :price, :amount, presence: true
  validates :qty, :price, :amount, numericality: { greater_than_or_equal_to: 0 }

  scope :chronological, -> { order(:date) }
  scope :for, ->(security) { where(security_id: security).order(:date) }

  delegate :ticker, to: :security

  def name
    security.name || ticker
  end

  def weight
    return nil unless amount
    return 0 if amount.zero?

    account.balance.zero? ? 1 : amount / account.balance * 100
  end

  # Basic approximation of cost-basis
  def avg_cost
    avg_cost = begin
      trades = account.trades
        .with_entry
        .where(security_id: security.id)
        .where("trades.qty > 0 AND entries.date <= ?", date)
      if trades.empty?
        nil
      else
        rates = ExchangeRate.where(date: trades.pluck("entries.date"), from_currency: trades.pluck(:currency), to_currency: account.currency)
        cost = 0
        trades.each do |trade|
          rate = rates.find { |r| r.date == trade.date && r.from_currency == trade.currency && r.to_currency == account.currency }
          cost += trade.price * trade.qty * (rate&.rate || 1)
        end
        cost / trades.sum(:qty)
      end
    end
    Money.new(avg_cost || price, currency)
  end

  def trend
    @trend ||= calculate_trend
  end

  def trades
    account.entries.where(entryable: account.trades.where(security: security)).reverse_chronological
  end

  def destroy_holding_and_entries!
    transaction do
      account.entries.where(entryable: account.trades.where(security: security)).destroy_all
      destroy
    end

    account.sync_later
  end

  private
    def calculate_trend
      return nil unless amount_money

      start_amount = qty * avg_cost

      Trend.new \
        current: amount_money,
        previous: start_amount
    end
end
