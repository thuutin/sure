class ChangeDefaultIdToUlid < ActiveRecord::Migration[7.2]
  def up
    # Change default value from gen_random_uuid() to ulid() for tables that use it
    change_column_default :active_storage_attachments, :id, -> { "ulid()" }
    change_column_default :active_storage_blobs, :id, -> { "ulid()" }
    change_column_default :active_storage_variant_records, :id, -> { "ulid()" }
    change_column_default :categories, :id, -> { "ulid()" }
  end

  def down
    # Revert back to gen_random_uuid() if needed
    change_column_default :active_storage_attachments, :id, -> { "gen_random_uuid()" }
    change_column_default :active_storage_blobs, :id, -> { "gen_random_uuid()" }
    change_column_default :active_storage_variant_records, :id, -> { "gen_random_uuid()" }
    change_column_default :categories, :id, -> { "gen_random_uuid()" }
  end
end
