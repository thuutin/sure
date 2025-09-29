class AddUuidDefaultsToAllTables < ActiveRecord::Migration[7.2]
  def change
    # Remove PostgreSQL-specific UUID defaults for SQLite compatibility
    # SQLite doesn't support gen_random_uuid(), so we'll handle UUIDs in Ruby

    # List of tables that need UUID default removal
    tables_with_uuid_defaults = [
      'accounts',
      'addresses',
      'api_keys',
      'balances',
      'budget_categories',
      'budgets',
      'chats',
      'credit_cards',
      'cryptos',
      'data_enrichments',
      'depositories',
      'entries',
      'exchange_rates',
      'families',
      'family_exports',
      'holdings',
      'impersonation_session_logs',
      'impersonation_sessions',
      'import_mappings',
      'import_rows',
      'imports',
      'investments',
      'invitations',
      'invite_codes',
      'loans',
      'merchants',
      'messages',
      'mobile_devices',
      # 'oauth_access_grants',
      # 'oauth_access_tokens',
      # 'oauth_applications',
      'other_assets',
      'other_liabilities',
      'plaid_accounts',
      'plaid_items',
      'properties',
      'rejected_transfers',
      'rule_actions',
      'rule_conditions',
      'rules',
      'securities',
      'security_prices',
      'sessions',
      # 'settings',
      'simplefin_accounts',
      'simplefin_items',
      'subscriptions',
      'syncs',
      'taggings',
      'tags',
      'tool_calls',
      'trades',
      'transactions',
      'transfers',
      'users',
      'valuations',
      'vehicles'
    ]

    tables_with_uuid_defaults.each do |table_name|
      if table_exists?(table_name)
        # Remove the default UUID generation for SQLite compatibility
        change_column_default table_name, :id, nil
        puts "Removed UUID default from #{table_name}"
      else
        raise ActiveRecord::MigrationError, "Table #{table_name} does not exist"
      end
    end
  end
end
