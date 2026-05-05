class ConvertBilledProductsArrayToJson < ActiveRecord::Migration[7.0]
  def change
    # Remove PostgreSQL array columns
    remove_column :plaid_items, :available_products, :string, array: true
    remove_column :plaid_items, :billed_products, :string, array: true
    remove_column :users, :otp_backup_codes, :string, array: true
    remove_column :users, :goals, :text, array: true

    # Add JSON columns with default empty array
    add_column :plaid_items, :available_products, :json, default: []
    add_column :plaid_items, :billed_products, :json, default: []
    add_column :users, :otp_backup_codes, :json, default: []
    add_column :users, :goals, :json, default: []

    # Convert JSONB to JSON for database compatibility
    remove_column :valuations, :locked_attributes, :jsonb
    remove_column :vehicles, :locked_attributes, :jsonb

    add_column :valuations, :locked_attributes, :json, default: {}
    add_column :vehicles, :locked_attributes, :json, default: {}

    # Remove PostgreSQL-specific functional index
    remove_index :securities, name: "index_securities_on_ticker_and_exchange_operating_mic_unique"

    # Add regular index instead
    add_index :securities, [ :ticker, :exchange_operating_mic ],
              name: "index_securities_on_ticker_and_exchange_operating_mic_unique",
              unique: true
  end
end
