class CategoryReference < ApplicationRecord
  has_many :contacts, foreign_key: :contact_type, inverse_of: :contact_type

  def self.list_by_category(category)
    where(category:).order(:display_order)
  end
end
