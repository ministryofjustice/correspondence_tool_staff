class CategoryReference < ApplicationRecord
  has_one :contact, foreign_key: :contact_type
end
