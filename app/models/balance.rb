class Balance < ApplicationRecord
  include Monetizable

  belongs_to :account

  validates :account, :date, :balance, presence: true
  validates :flows_factor, inclusion: { in: [ -1, 1 ] }

  before_save :calculate_derived_balances
  after_initialize :calculate_derived_balances

  monetize :balance, :cash_balance,
           :start_cash_balance, :start_non_cash_balance, :start_balance,
           :cash_inflows, :cash_outflows, :non_cash_inflows, :non_cash_outflows, :net_market_flows,
           :cash_adjustments, :non_cash_adjustments,
           :end_cash_balance, :end_non_cash_balance, :end_balance

  scope :in_period, ->(period) { period.nil? ? all : where(date: period.date_range) }
  scope :chronological, -> { order(:date) }

  def balance_trend
    Trend.new(
      current: end_balance_money,
      previous: start_balance_money,
      favorable_direction: favorable_direction
    )
  end

  private

    def favorable_direction
      flows_factor == -1 ? "down" : "up"
    end

    def calculate_derived_balances
      raise ArgumentError, "flows_factor is nil" if flows_factor.nil?
      raise ArgumentError, "start_cash_balance is nil" if start_cash_balance.nil?
      raise ArgumentError, "start_non_cash_balance is nil" if start_non_cash_balance.nil?
      raise ArgumentError, "cash_inflows is nil" if cash_inflows.nil?
      raise ArgumentError, "cash_outflows is nil" if cash_outflows.nil?
      raise ArgumentError, "non_cash_inflows is nil" if non_cash_inflows.nil?
      raise ArgumentError, "non_cash_outflows is nil" if non_cash_outflows.nil?
      raise ArgumentError, "net_market_flows is nil" if net_market_flows.nil?
      raise ArgumentError, "cash_adjustments is nil" if cash_adjustments.nil?
      raise ArgumentError, "non_cash_adjustments is nil" if non_cash_adjustments.nil?
      # Calculate start_balance
      self.start_balance = start_cash_balance + start_non_cash_balance

      # Calculate end_cash_balance
      self.end_cash_balance = (start_cash_balance + ((cash_inflows - cash_outflows) * flows_factor)) + cash_adjustments

      # Calculate end_non_cash_balance
      self.end_non_cash_balance = ((start_non_cash_balance + ((non_cash_inflows - non_cash_outflows) * flows_factor)) + net_market_flows) + non_cash_adjustments

      # Calculate end_balance
      self.end_balance = end_cash_balance + end_non_cash_balance
    end
end
