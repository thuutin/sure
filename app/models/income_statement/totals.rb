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

    def rates
      @rates ||= begin
        currencies = entries.map { |e| e.currency }.uniq
        min_date = entries.minimum(:date)
        max_date = entries.maximum(:date)
        ExchangeRate.where(from_currency: currencies, to_currency: @family.currency, date: min_date..max_date)
        .select(:from_currency, :to_currency, :date, :rate)
        .group_by { |r| [ r.from_currency, r.to_currency, r.date ] }
        .transform_values { |r| r.first.rate }
      end
    end

    def build_totals
      incomes = categories.map do |category|
        income_entries = entries.filter { |e| transactions[e.entryable_id]&.category_id == category.id && e.amount < 0 }
        transactions_count = income_entries.count
        total = 0
        income_entries.each do |e|
          total += e.amount * (rates[[ e.currency, @family.currency, e.date ]] || 1)
        end
        TotalsRow.new(
          parent_category_id: category.parent_id,
          category_id: category.id,
          classification: "income",
          total: total.abs,
          transactions_count: transactions_count
        )
      end

      expenses = categories.map do |category|
        expense_entries = entries.filter { |e| transactions[e.entryable_id]&.category_id == category.id && e.amount >= 0 }
        total = 0
        expense_entries.each do |e|
          total += e.amount * (rates[[ e.currency, @family.currency, e.date ]] || 1)
        end
        transactions_count = expense_entries.count
        TotalsRow.new(
          parent_category_id: category.parent_id,
          category_id: category.id,
          classification: "expense",
          total: total.abs,
          transactions_count: transactions_count
        )
      end
      incomes + expenses
    end
end
