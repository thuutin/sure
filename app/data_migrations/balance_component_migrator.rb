class BalanceComponentMigrator
  def self.run
    ActiveRecord::Base.transaction do
      # Step 1: Update flows factor
      Balance.all.each do |balance|
        balance.flows_factor = balance.account.classification == "asset" ? 1 : -1
        balance.save!
      end

      # Step 2: Set start values using LOCF (Last Observation Carried Forward)
      Balance.all.each do |balance|
        prev = Balance
          .where(account_id: balance.account_id, currency: balance.currency)
          .where("date < ?", balance.date).order(date: :desc)
          .first
        if prev
          balance.start_cash_balance = prev.cash_balance
          balance.start_non_cash_balance = prev.balance - prev.cash_balance
        else
          balance.start_cash_balance = 0
          balance.start_non_cash_balance = 0
        end
        balance.save!
      end

      # Step 3: Calculate net inflows
      # A slight workaround to the fact that we can't easily derive inflows/outflows from our current data model, and
      # the tradeoff not worth it since each new sync will fix it. So instead, we sum up *net* flows, and throw the signed
      # amount in the "inflows" column, and zero-out the "outflows" column so our math works correctly with incomplete data.
      Balance.all.each do |balance|
        balance.cash_inflows = (balance.cash_balance - balance.start_cash_balance) * balance.flows_factor
        balance.cash_outflows = 0
        balance.non_cash_inflows = ((balance.balance - balance.cash_balance) - balance.start_non_cash_balance) * balance.flows_factor
        balance.non_cash_outflows = 0
        balance.net_market_flows = 0
        balance.save!
      end

      # Verify data integrity
      # All end_balance values should match the original balance
      invalid_balances = Balance.all.filter do |balance|
        (balance.balance - balance.end_balance).abs > 0.0001
      end
      invalid_count = invalid_balances.count

      if invalid_count > 0
        raise "Data migration failed validation: #{invalid_count} balances have incorrect end_balance values"
      end
    end
  end
end
