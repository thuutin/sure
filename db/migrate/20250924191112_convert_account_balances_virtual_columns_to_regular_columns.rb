class ConvertAccountBalancesVirtualColumnsToRegularColumns < ActiveRecord::Migration[7.0]
  def change
    # Remove all virtual columns
    remove_column :balances, :start_balance, :decimal
    remove_column :balances, :end_cash_balance, :decimal
    remove_column :balances, :end_non_cash_balance, :decimal
    remove_column :balances, :end_balance, :decimal

    # Add regular decimal columns
    add_column :balances, :start_balance, :decimal, precision: 19, scale: 4
    add_column :balances, :end_cash_balance, :decimal, precision: 19, scale: 4
    add_column :balances, :end_non_cash_balance, :decimal, precision: 19, scale: 4
    add_column :balances, :end_balance, :decimal, precision: 19, scale: 4

    # Populate the columns based on the original virtual column logic
    execute <<-SQL
      UPDATE balances#{' '}
      SET#{' '}
        start_balance = (start_cash_balance + start_non_cash_balance),
        end_cash_balance = ((start_cash_balance + ((cash_inflows - cash_outflows) * (flows_factor)::numeric)) + cash_adjustments),
        end_non_cash_balance = (((start_non_cash_balance + ((non_cash_inflows - non_cash_outflows) * (flows_factor)::numeric)) + net_market_flows) + non_cash_adjustments),
        end_balance = (((start_cash_balance + ((cash_inflows - cash_outflows) * (flows_factor)::numeric)) + cash_adjustments) + (((start_non_cash_balance + ((non_cash_inflows - non_cash_outflows) * (flows_factor)::numeric)) + net_market_flows) + non_cash_adjustments))
    SQL
  end
end
