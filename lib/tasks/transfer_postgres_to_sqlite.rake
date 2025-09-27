namespace :db do
  desc "Transfer data from PostgreSQL to SQLite"
  task transfer_to_sqlite: :environment do
    # Configuration
    postgres_config = {
      adapter: "postgresql",
      host: "localhost",
      database: "maybe-development",  # Update with your PostgreSQL database name
      username: "maybe_user",      # Update with your PostgreSQL username
      password: "maybe_password"       # Update with your PostgreSQL password
    }

    sqlite_config = {
      adapter: "sqlite3",
      database: "storage/development_primary.sqlite3"
    }

    puts "Starting data transfer from PostgreSQL to SQLite..."

    # Connect to PostgreSQL
    postgres_conn = ActiveRecord::Base.establish_connection(postgres_config)

    # Connect to SQLite
    sqlite_conn = ActiveRecord::Base.establish_connection(sqlite_config)

    # Ensure SQLite database exists and is migrated
    puts "Setting up SQLite database..."
    system("RAILS_ENV=development bin/rails db:drop:primary")
    system("RAILS_ENV=development bin/rails db:create:primary")
    system("RAILS_ENV=development bin/rails db:schema:load:primary")

    # Disable foreign key checks for faster data insertion
    puts "Disabling foreign key checks..."
    tables = [
     "cryptos",
     "oauth_access_grants", "users", "chats", "messages", "settings", "security_prices", "oauth_access_tokens",
      "accounts", "active_storage_attachments", "active_storage_blobs", "active_storage_variant_records", "addresses",
       "api_keys", "balances", "budget_categories", "budgets", "categories", "credit_cards", "data_enrichments",
       "depositories", "entries", "exchange_rates", "families", "family_exports", "holdings", "impersonation_session_logs",
        "impersonation_sessions", "import_mappings", "import_rows", "imports", "investments", "invitations", "invite_codes",
        "loans", "merchants", "mobile_devices", "other_assets", "oauth_applications", "other_liabilities", "plaid_items",
        "plaid_accounts", "properties", "rejected_transfers", "rule_actions", "rule_conditions", "rules", "securities", "sessions",
        "simplefin_accounts", "simplefin_items", "subscriptions", "syncs", "taggings", "tags", "tool_calls", "trades",
        "transactions", "transfers",  "valuations", "vehicles"
      ]
    # Transfer each table
    tables.each do |table_name|
      puts "\nTransferring #{table_name}"

      begin
        # Switch to PostgreSQL connection
        ActiveRecord::Base.establish_connection(postgres_config)

        # Get all data from PostgreSQL table
        postgres_data = ActiveRecord::Base.connection.execute("SELECT * FROM #{table_name}")

        if postgres_data.count == 0
          puts "  No data in #{table_name}, skipping..."
          next
        end

        # Switch to SQLite connection
        ActiveRecord::Base.establish_connection(sqlite_config)
        ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
        ActiveRecord::Base.connection.execute("PRAGMA strict = ON")

        # Clear existing data in SQLite table
        ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}")

        # Get column names
        columns = postgres_data.fields

        # Insert data in batches
        columns_str = columns.join(", ")
        postgres_data.each do |row|
          values = columns.map do |col|
            value = row[col]
            case value
            when nil
              "NULL"
            when String
              "'#{value.gsub("'", "''")}'"
            when Time, Date, DateTime
              "'#{value}'"
            when Array
              # Convert arrays to JSON
              "'#{value.to_json}'"
            when Hash
              # Convert hashes to JSON
              "'#{value.to_json}'"
            when TrueClass, FalseClass
              value ? "1" : "0"
            else
              "'#{value}'"
            end
          end
          values_str = values.join(", ")
          insert_sql = "INSERT INTO #{table_name} (#{columns_str}) VALUES (#{values_str})"
          ActiveRecord::Base.connection.execute(insert_sql)
        end

        puts "  ✓ Transferred #{postgres_data.count} records"

      rescue => e
        puts "  ✗ Error transferring #{table_name}: #{e.message}"
        puts "  Continuing with next table..."
      end
    end

    # Re-enable foreign key checks
    puts "Re-enabling foreign key checks..."
    ActiveRecord::Base.establish_connection(sqlite_config)
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")

    # Restore original connection
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)

    puts "\nData transfer completed!"
    puts "SQLite database created at: #{sqlite_config[:database]}"
  end
end
