class CategoryReference < ApplicationRecord

  def self.find_by_category(category)
    category_references = self.where(category: category).order(:display_order)
    category_reference_hash = {}
    binding.pry
    if category_references.any?
      category_references.each do |category_reference|
        category_reference_hash[category_reference.code.to_sym] = category_reference.value
      end
      category_reference_hash
    else
      nil
    end
  end
end
