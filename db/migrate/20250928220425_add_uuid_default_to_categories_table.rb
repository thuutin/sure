class AddUuidDefaultToCategoriesTable < ActiveRecord::Migration[7.2]
  def change
    # Add UUID default value for categories table primary key
    change_column_default :categories, :id, -> { "gen_random_uuid()" }
  end
end
