class RemoveFunctionalAndPartialIndexes < ActiveRecord::Migration[7.0]
  def change
    # Remove functional index on entries.name
    remove_index :entries, name: "index_entries_on_lower_name"

    # Remove partial indexes on merchants
    remove_index :merchants, name: "index_merchants_on_family_id_and_name"
    remove_index :merchants, name: "index_merchants_on_source_and_name"

    # Remove partial index on users.otp_secret
    remove_index :users, name: "index_users_on_otp_secret"

    # Add regular indexes to replace them

    # Regular index on entries.name (for case-insensitive searches, handle in application)
    add_index :entries, :name, name: "index_entries_on_name"

    # Regular indexes on merchants (remove unique constraint since we can't enforce it per type)
    add_index :merchants, [ :family_id, :name ], name: "index_merchants_on_family_id_and_name"
    add_index :merchants, [ :source, :name ], name: "index_merchants_on_source_and_name"

    # Regular index on users.otp_secret (remove unique constraint since we can't enforce it for non-null only)
    add_index :users, :otp_secret, name: "index_users_on_otp_secret"
  end
end
