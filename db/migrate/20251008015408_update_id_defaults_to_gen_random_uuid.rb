class UpdateIdDefaultsToGenRandomUuid < ActiveRecord::Migration[8.0]
  def change
    # List of all tables with string ID columns that need gen_random_uuid() default
    tables_with_string_ids = [
      'accounts', 'addresses', 'api_keys', 'balances', 'budget_categories', 'budgets',
      'chats', 'credit_cards', 'cryptos', 'data_enrichments', 'depositories', 'entries',
      'exchange_rates', 'families', 'family_exports', 'holdings', 'impersonation_session_logs',
      'impersonation_sessions', 'import_mappings', 'import_rows', 'imports', 'investments',
      'invitations', 'invite_codes', 'loans', 'merchants', 'messages', 'mobile_devices',
      'other_assets', 'other_liabilities', 'plaid_accounts', 'plaid_items', 'properties',
      'rejected_transfers', 'rule_actions', 'rule_conditions', 'rules', 'securities',
      'security_prices', 'sessions', 'simplefin_accounts', 'simplefin_items', 'subscriptions',
      'syncs', 'taggings', 'tags', 'tool_calls', 'trades', 'transactions', 'transfers',
      'users', 'valuations', 'vehicles',
      'active_storage_attachments', 'active_storage_blobs', 'active_storage_variant_records',
      'categories'
    ]

    tables_with_string_ids.each do |table_name|
      # Check if table exists and has an id column
      if table_exists?(table_name) && column_exists?(table_name, :id)
        # Update the id column to use gen_random_uuid() as default
        change_column_default table_name, :id, -> { "gen_random_uuid()" }
      end
    end
  end
end
