class AddUuidDefaultsToActiveStorageTables < ActiveRecord::Migration[7.2]
  def change
    # Add UUID default values for Active Storage tables primary keys
    change_column_default :active_storage_attachments, :id, -> { "gen_random_uuid()" }
    change_column_default :active_storage_blobs, :id, -> { "gen_random_uuid()" }
    change_column_default :active_storage_variant_records, :id, -> { "gen_random_uuid()" }
  end
end
