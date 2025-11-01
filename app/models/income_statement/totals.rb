class IncomeStatement::Totals
  def initialize(family, transactions_scope:)
    @family = family
    @transactions_scope = transactions_scope
  end

  def call
    build_totals
  end

  private
    TotalsRow = Data.define(:parent_category_id, :category_id, :classification, :total, :transactions_count)

    def transactions
      @transactions ||= @transactions_scope
        .where.not(kind: [ "funds_movement", "one_time", "cc_payment" ])
        .select(:id, :category_id)
        .group_by { |t| t.id }
        .transform_values { |t| t.first }
    end

    def entries
      @entries ||= Entry
      .where(entryable_id: transactions.keys, entryable_type: "Transaction", excluded: false)
      .select(:id, :amount, :currency, :date, :entryable_id)
    end

    def categories
      @categories ||= Category.where(id: transactions.values.map { |t| t.category_id }.uniq).select(:id, :parent_id)
    end

    def rate_for(from, to, date)
      if from == to
        return 1
      end
      rates = exchange_rates.dig([ from, to ]) || []
      closest_rate = rates.bsearch { |rate| rate.date <= date }
      closest_rate&.rate || 1
    end

    def exchange_rates
      @rates ||= begin
        currencies = entries.map { |e| e.currency }.uniq
        min_date = entries.minimum(:date)
        max_date = entries.maximum(:date)
        ExchangeRate.where(date: (min_date - 30.days)..max_date) # extend the range so exchange rates are likely to be available
          .and(ExchangeRate.where(to_currency: @family.currency))
          .and(ExchangeRate.where(from_currency: currencies))
          .select(:id, :date, :rate, :from_currency, :to_currency)
          .group_by { |er| [ er.from_currency, er.to_currency ] }
          .transform_values { |rates| rates.sort_by(&:date).reverse }
      end
    end

    def should_include_entry?(entry, classification)
      case classification
      when "income"
        entry.amount < 0
      when "expense"
        entry.amount >= 0
      end
    end

    def build_totals
      [ "income", "expense" ].map do |classification|
        no_category = OpenStruct.new(id: nil, parent_id: nil)
        include_no_category = categories.to_a + [ no_category ]
        include_no_category.map do |category|
          entries_by_category = entries.filter { |e| transactions[e.entryable_id]&.category_id == category.id && should_include_entry?(e, classification) }
          transactions_count = entries_by_category.count
          total = 0
          entries_by_category.each do |e|
            total += e.amount * (rate_for(e.currency, @family.currency, e.date) || 1)
          end
          TotalsRow.new(
            parent_category_id: category.parent_id,
            category_id: category.id,
            classification: classification,
            total: total.abs,
            transactions_count: transactions_count
          )
        end
      end.flatten
    end
end
