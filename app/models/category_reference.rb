class CategoryReference < ApplicationRecord

  def self.list_by_category(category)
    self.where(category: category).order(:display_order)
  end
end
