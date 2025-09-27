class ApplicationRecord < ActiveRecord::Base
  include UuidGenerator
  primary_abstract_class
end
