# Concern for generating UUIDs before saving
# Compatible with both PostgreSQL and SQLite
# Automatically detects string primary keys and only generates UUIDs for those
module UuidGenerator
  extend ActiveSupport::Concern

  included do
    validates :id, presence: true, if: :uses_string_primary_key?
    before_validation :generate_uuid, if: :uses_string_primary_key?
  end

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end

    def uses_string_primary_key?
      # Check if the primary key column is a string type
      primary_key_column = self.class.columns_hash[self.class.primary_key]
      primary_key_column&.type == :string
    end
end
