class ChangeJsonBToJson < ActiveRecord::Migration[7.2]
  def change
    change_column :accounts, :locked_attributes, :json
    change_column :chats, :error, :json
    change_column :credit_cards, :locked_attributes, :json
    change_column :cryptos, :locked_attributes, :json

    change_column :data_enrichments, :value, :json
    change_column :data_enrichments, :metadata, :json

    change_column :depositories, :locked_attributes, :json

    change_column :entries, :locked_attributes, :json

    change_column :imports, :column_mappings, :json

    change_column :investments, :locked_attributes, :json

    change_column :loans, :locked_attributes, :json

    change_column :other_assets, :locked_attributes, :json

    change_column :other_liabilities, :locked_attributes, :json

    change_column :plaid_accounts, :raw_payload, :json
    change_column :plaid_accounts, :raw_transactions_payload, :json
    change_column :plaid_accounts, :raw_investments_payload, :json
    change_column :plaid_accounts, :raw_liabilities_payload, :json

    change_column :plaid_items, :raw_payload, :json
    change_column :plaid_items, :raw_institution_payload, :json

    change_column :properties, :locked_attributes, :json

    change_column :sessions, :prev_transaction_page_params, :json
    change_column :sessions, :data, :json

    change_column :simplefin_accounts, :raw_payload, :json
    change_column :simplefin_accounts, :raw_transactions_payload, :json
    change_column :simplefin_accounts, :extra, :json
    change_column :simplefin_accounts, :org_data, :json

    change_column :simplefin_items, :raw_payload, :json
    change_column :simplefin_items, :raw_institution_payload, :json

    change_column :syncs, :data, :json

    change_column :tool_calls, :function_arguments, :json
    change_column :tool_calls, :function_result, :json

    change_column :trades, :locked_attributes, :json
    change_column :transactions, :locked_attributes, :json
  end
end
