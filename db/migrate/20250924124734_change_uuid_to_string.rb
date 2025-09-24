class ChangeUuidToString < ActiveRecord::Migration[7.2]
  def change
    # remove foreign key constraints
    remove_all_foreign_keys

    # accounts
    change_column :accounts, :id, :string, null: false
    change_column :accounts, :family_id, :string, null: false
    change_column :accounts, :accountable_id, :string
    change_column :accounts, :import_id, :string
    change_column :accounts, :plaid_account_id, :string
    change_column :accounts, :simplefin_account_id, :string

    # active_storage_attachments
    change_column :active_storage_attachments, :id, :string, null: false
    change_column :active_storage_attachments, :record_id, :string, null: false
    change_column :active_storage_attachments, :blob_id, :string, null: false

    # active_storage_blobs
    change_column :active_storage_blobs, :id, :string, null: false

    # active_storage_variant_records
    change_column :active_storage_variant_records, :id, :string, null: false
    change_column :active_storage_variant_records, :blob_id, :string, null: false

    # addresses
    change_column :addresses, :id, :string, null: false
    change_column :addresses, :addressable_id, :string

    # api_keys
    change_column :api_keys, :id, :string, null: false
    change_column :api_keys, :user_id, :string, null: false

    # balances
    change_column :balances, :id, :string, null: false
    change_column :balances, :account_id, :string, null: false

    # budget_categories
    change_column :budget_categories, :id, :string, null: false
    change_column :budget_categories, :budget_id, :string, null: false
    change_column :budget_categories, :category_id, :string, null: false

    # budgets
    change_column :budgets, :id, :string, null: false
    change_column :budgets, :family_id, :string, null: false

    # categories
    change_column :categories, :id, :string, null: false
    change_column :categories, :family_id, :string, null: false
    change_column :categories, :parent_id, :string

    # chats
    change_column :chats, :id, :string, null: false
    change_column :chats, :user_id, :string, null: false
    change_column :chats, :title, :string, null: false

    # credit_cards
    change_column :credit_cards, :id, :string, null: false
    # cryptos
    change_column :cryptos, :id, :string, null: false

    # data_enrichments
    change_column :data_enrichments, :id, :string, null: false
    change_column :data_enrichments, :enrichable_id, :string, null: false
    # depositories
    change_column :depositories, :id, :string, null: false
    # entries
    change_column :entries, :id, :string, null: false
    change_column :entries, :account_id, :string, null: false
    change_column :entries, :entryable_id, :string
    change_column :entries, :import_id, :string
    # exchange_rates
    change_column :exchange_rates, :id, :string, null: false
    # families
    change_column :families, :id, :string, null: false
    # family_exports
    change_column :family_exports, :id, :string, null: false
    change_column :family_exports, :family_id, :string, null: false
    # holdings
    change_column :holdings, :id, :string, null: false
    change_column :holdings, :account_id, :string, null: false
    change_column :holdings, :security_id, :string, null: false
    # impersonation_session_logs
    change_column :impersonation_session_logs, :id, :string, null: false
    change_column :impersonation_session_logs, :impersonation_session_id, :string, null: false
    # impersonation_sessions
    change_column :impersonation_sessions, :id, :string, null: false
    change_column :impersonation_sessions, :impersonator_id, :string, null: false
    change_column :impersonation_sessions, :impersonated_id, :string, null: false
    # import_mappings
    change_column :import_mappings, :id, :string, null: false
    change_column :import_mappings, :import_id, :string, null: false
    change_column :import_mappings, :mappable_id, :string
    # import_rows
    change_column :import_rows, :id, :string, null: false
    change_column :import_rows, :import_id, :string, null: false
    # imports
    change_column :imports, :id, :string, null: false
    change_column :imports, :family_id, :string, null: false
    change_column :imports, :account_id, :string
    # investments
    change_column :investments, :id, :string, null: false
    # invitations
    change_column :invitations, :id, :string, null: false
    change_column :invitations, :family_id, :string, null: false
    change_column :invitations, :inviter_id, :string, null: false
    # invite_codes
    change_column :invite_codes, :id, :string, null: false
    # loans
    change_column :loans, :id, :string, null: false
    # merchants
    change_column :merchants, :id, :string, null: false
    change_column :merchants, :family_id, :string
    # messages
    change_column :messages, :id, :string, null: false
    change_column :messages, :chat_id, :string, null: false
    # mobile_devices
    change_column :mobile_devices, :id, :string, null: false
    change_column :mobile_devices, :user_id, :string, null: false
    # oauth_access_grants
    # change_column :oauth_access_grants, :id, :string, null: false
    # oauth_access_tokens
    # change_column :oauth_access_tokens, :id, :string, null: false
    # oauth_applications
    # change_column :oauth_applications, :id, :string, null: false
    change_column :oauth_applications, :owner_id, :string
    # other_assets
    change_column :other_assets, :id, :string, null: false
    # other_liabilities
    change_column :other_liabilities, :id, :string, null: false
    # plaid_accounts
    change_column :plaid_accounts, :id, :string, null: false
    change_column :plaid_accounts, :plaid_item_id, :string, null: false
    # plaid_items
    change_column :plaid_items, :id, :string, null: false
    change_column :plaid_items, :family_id, :string, null: false
    # properties
    change_column :properties, :id, :string, null: false

    # rejected_transfers
    change_column :rejected_transfers, :id, :string, null: false
    change_column :rejected_transfers, :inflow_transaction_id, :string, null: false
    change_column :rejected_transfers, :outflow_transaction_id, :string, null: false
    # rule_actions
    change_column :rule_actions, :id, :string, null: false
    change_column :rule_actions, :rule_id, :string, null: false
    # rule_conditions
    change_column :rule_conditions, :id, :string, null: false
    change_column :rule_conditions, :rule_id, :string
    change_column :rule_conditions, :parent_id, :string
    # rules
    change_column :rules, :id, :string, null: false
    change_column :rules, :family_id, :string, null: false
    # securities
    change_column :securities, :id, :string, null: false
    # security_prices
    change_column :security_prices, :id, :string, null: false
    change_column :security_prices, :security_id, :string
    # sessions
    change_column :sessions, :id, :string, null: false
    change_column :sessions, :user_id, :string, null: false
    change_column :sessions, :active_impersonator_session_id, :string
    # settings
    # change_column :settings, :id, :string, null: false
    # simplefin_accounts
    change_column :simplefin_accounts, :id, :string, null: false
    change_column :simplefin_accounts, :simplefin_item_id, :string, null: false
    # simplefin_items
    change_column :simplefin_items, :id, :string, null: false
    change_column :simplefin_items, :family_id, :string, null: false
    # subscriptions
    change_column :subscriptions, :id, :string, null: false
    change_column :subscriptions, :family_id, :string, null: false
    # syncs
    change_column :syncs, :id, :string, null: false
    change_column :syncs, :syncable_id, :string, null: false
    change_column :syncs, :parent_id, :string
    # taggings
    change_column :taggings, :id, :string, null: false
    change_column :taggings, :tag_id, :string, null: false
    change_column :taggings, :taggable_id, :string
    # tags
    change_column :tags, :id, :string, null: false
    change_column :tags, :family_id, :string, null: false
    # tool_calls
    change_column :tool_calls, :id, :string, null: false
    change_column :tool_calls, :message_id, :string, null: false
    # trades
    change_column :trades, :id, :string, null: false
    change_column :trades, :security_id, :string, null: false
    # transactions
    change_column :transactions, :id, :string, null: false
    change_column :transactions, :category_id, :string
    change_column :transactions, :merchant_id, :string
    # transfers
    change_column :transfers, :id, :string, null: false
    change_column :transfers, :inflow_transaction_id, :string, null: false
    change_column :transfers, :outflow_transaction_id, :string, null: false
    # users
    change_column :users, :id, :string, null: false
    change_column :users, :family_id, :string, null: false
    change_column :users, :last_viewed_chat_id, :string

    # valuations
    change_column :valuations, :id, :string, null: false
    # vehicles
    change_column :vehicles, :id, :string, null: false

    add_all_foreign_keys
    # raise "Not implemented yet, WHAT"
  end

  def remove_all_foreign_keys
    remove_foreign_key :accounts, :families
    remove_foreign_key :accounts, :imports
    remove_foreign_key :accounts, :plaid_accounts
    remove_foreign_key :accounts, :simplefin_accounts
    remove_foreign_key :active_storage_attachments, :active_storage_blobs
    remove_foreign_key :active_storage_variant_records, :active_storage_blobs
    remove_foreign_key :api_keys, :users
    remove_foreign_key :balances, :accounts
    remove_foreign_key :budget_categories, :budgets
    remove_foreign_key :budget_categories, :categories
    remove_foreign_key :budgets, :families
    remove_foreign_key :categories, :families
    remove_foreign_key :chats, :users
    remove_foreign_key :entries, :accounts
    remove_foreign_key :entries, :imports
    remove_foreign_key :family_exports, :families
    remove_foreign_key :holdings, :accounts
    remove_foreign_key :holdings, :securities
    remove_foreign_key :impersonation_session_logs, :impersonation_sessions
    remove_foreign_key :impersonation_sessions, :users, column: :impersonated_id
    remove_foreign_key :impersonation_sessions, :users, column: :impersonator_id
    remove_foreign_key :import_rows, :imports
    remove_foreign_key :imports, :families
    remove_foreign_key :invitations, :families
    remove_foreign_key :invitations, :users, column: :inviter_id
    remove_foreign_key :merchants, :families
    remove_foreign_key :messages, :chats
    remove_foreign_key :mobile_devices, :users
    remove_foreign_key :oauth_access_grants, :oauth_applications, column: :application_id
    remove_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id
    remove_foreign_key :plaid_accounts, :plaid_items
    remove_foreign_key :plaid_items, :families
    remove_foreign_key :rejected_transfers, :transactions, column: :inflow_transaction_id
    remove_foreign_key :rejected_transfers, :transactions, column: :outflow_transaction_id
    remove_foreign_key :rule_actions, :rules
    remove_foreign_key :rule_conditions, :rule_conditions, column: :parent_id
    remove_foreign_key :rule_conditions, :rules
    remove_foreign_key :rules, :families
    remove_foreign_key :security_prices, :securities
    remove_foreign_key :sessions, :impersonation_sessions, column: :active_impersonator_session_id
    remove_foreign_key :sessions, :users
    remove_foreign_key :simplefin_accounts, :simplefin_items
    remove_foreign_key :simplefin_items, :families
    remove_foreign_key :subscriptions, :families
    remove_foreign_key :syncs, :syncs, column: :parent_id
    remove_foreign_key :taggings, :tags
    remove_foreign_key :tags, :families
    remove_foreign_key :tool_calls, :messages
    remove_foreign_key :trades, :securities
    remove_foreign_key :transactions, :categories
    remove_foreign_key :transactions, :merchants
    remove_foreign_key :transfers, :transactions, column: :inflow_transaction_id
    remove_foreign_key :transfers, :transactions, column: :outflow_transaction_id
    remove_foreign_key :users, :chats, column: :last_viewed_chat_id
    remove_foreign_key :users, :families
  end

  def add_all_foreign_keys
    add_foreign_key :accounts, :families
    add_foreign_key :accounts, :imports
    add_foreign_key :accounts, :plaid_accounts
    add_foreign_key :accounts, :simplefin_accounts
    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    add_foreign_key :active_storage_variant_records, :active_storage_blobs, column: :blob_id
    add_foreign_key :api_keys, :users
    add_foreign_key :balances, :accounts, on_delete: :cascade
    add_foreign_key :budget_categories, :budgets
    add_foreign_key :budget_categories, :categories
    add_foreign_key :budgets, :families
    add_foreign_key :categories, :families
    add_foreign_key :chats, :users
    add_foreign_key :entries, :accounts
    add_foreign_key :entries, :imports
    add_foreign_key :family_exports, :families
    add_foreign_key :holdings, :accounts
    add_foreign_key :holdings, :securities
    add_foreign_key :impersonation_session_logs, :impersonation_sessions
    add_foreign_key :impersonation_sessions, :users, column: :impersonated_id
    add_foreign_key :impersonation_sessions, :users, column: :impersonator_id
    add_foreign_key :import_rows, :imports
    add_foreign_key :imports, :families
    add_foreign_key :invitations, :families
    add_foreign_key :invitations, :users, column: :inviter_id
    add_foreign_key :merchants, :families
    add_foreign_key :messages, :chats
    add_foreign_key :mobile_devices, :users
    add_foreign_key :oauth_access_grants, :oauth_applications, column: :application_id
    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id
    add_foreign_key :plaid_accounts, :plaid_items
    add_foreign_key :plaid_items, :families
    add_foreign_key :rejected_transfers, :transactions, column: :inflow_transaction_id
    add_foreign_key :rejected_transfers, :transactions, column: :outflow_transaction_id
    add_foreign_key :rule_actions, :rules
    add_foreign_key :rule_conditions, :rule_conditions, column: :parent_id
    add_foreign_key :rule_conditions, :rules
    add_foreign_key :rules, :families
    add_foreign_key :security_prices, :securities
    add_foreign_key :sessions, :impersonation_sessions, column: :active_impersonator_session_id
    add_foreign_key :sessions, :users
    add_foreign_key :simplefin_accounts, :simplefin_items
    add_foreign_key :simplefin_items, :families
    add_foreign_key :subscriptions, :families
    add_foreign_key :syncs, :syncs, column: :parent_id
    add_foreign_key :taggings, :tags
    add_foreign_key :tags, :families
    add_foreign_key :tool_calls, :messages
    add_foreign_key :trades, :securities
    add_foreign_key :transactions, :categories, on_delete: :nullify
    add_foreign_key :transactions, :merchants
    add_foreign_key :transfers, :transactions, column: :inflow_transaction_id, on_delete: :cascade
    add_foreign_key :transfers, :transactions, column: :outflow_transaction_id, on_delete: :cascade
    add_foreign_key :users, :chats, column: :last_viewed_chat_id
    add_foreign_key :users, :families
  end
end
