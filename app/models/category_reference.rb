class CategoryReference < ApplicationRecord
  has_many :contacts, foreign_key: :contact_type, inverse_of: :contact_type, dependent: :nullify

  def self.list_by_category(category)
    self.where(category: category).order(:display_order)
  end

end
