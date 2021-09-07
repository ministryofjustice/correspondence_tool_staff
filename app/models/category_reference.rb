class CategoryReference < ApplicationRecord

  def self.list_by_category(category)
    self.where(category: category).order(:display_order)
  end

  def self.display_value_by_category_and_code(category, code)
    self.find_by(category: category, code: code).value
  end
end
