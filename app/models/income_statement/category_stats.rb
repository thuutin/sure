class IncomeStatement::CategoryStats
  def initialize(family, interval: "month")
    @family = family
    @interval = interval
  end

  def call
    build_category_stats
  end

  private
    StatRow = Data.define(:category_id, :classification, :median, :avg)

    def transactions
      @transactions ||= @family.transactions
        .where.not(kind: [ "funds_movement", "one_time", "cc_payment" ])
        .select(:id, :category_id)
        .group_by { |t| t.id }
        .transform_values { |t| t.first }
    end

    def date_trunc(interval, date)
      case interval
      when "month"
        date.beginning_of_month
      when "week"
        date.beginning_of_week
      else
        raise "Invalid interval: #{interval}"
      end
    end

    def entry_by_intervals
      @entries ||= begin
        Entry
          .where(entryable_id: transactions.keys, entryable_type: "Transaction", excluded: false)
          .select(:id, :amount, :currency, :date, :entryable_id)
          .group_by { |e| date_trunc(@interval, e.date) }
      end
    end

    def rates
      @rates ||= begin
        entries = entry_by_intervals.values.flatten
        currencies = entries.map { |e| e.currency }.uniq
        min_date = entries.minimum(:date)
        max_date = entries.maximum(:date)
        ExchangeRate.where(from_currency: currencies, to_currency: @family.currency, date: min_date..max_date)
        .select(:from_currency, :to_currency, :date, :rate)
        .group_by { |r| [ r.from_currency, r.to_currency, r.date ] }
        .transform_values { |r| r.first.rate }
      end
    end

    def category_ids
      @category_ids ||= transactions.values.map { |t| t.category_id }.uniq
    end

    def median_for(entries)
      if entries.count > 0
        mid = entries.count / 2
        if entries.count.odd?
          entries[mid]
        else
          (entries[mid - 1] + entries[mid]) / 2.0
        end.abs
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

    def build_category_stats
      [ "income", "expense" ].map do |classification|
        category_ids.map do |category_id|
          sum_amount_by_intervals = entry_by_intervals
            .transform_values { |entries| entries.filter {
              |e| transactions[e.entryable_id]&.category_id == category_id && should_include_entry?(e, classification)
            } }
            .transform_values { |entries|
              entries = entries.map { |e| e.amount * (rates[[ e.currency, @family.currency, e.date ]] || 1) }
              entries.sum.abs
            }
            .values
            .sort
          transactions_count = sum_amount_by_intervals.count
          total = sum_amount_by_intervals.sum
          StatRow.new(
            category_id: category_id,
            classification: classification,
            median: median_for(sum_amount_by_intervals),
            avg: transactions_count.positive? ? total.fdiv(transactions_count) : 0
          )
        end
      end.flatten
    end
end
