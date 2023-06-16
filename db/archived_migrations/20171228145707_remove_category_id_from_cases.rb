class RemoveCategoryIdFromCases < ActiveRecord::Migration[5.0]
  def up
    remove_reference :cases, :category
  end

  def down
    add_reference :cases, :category, foreign_key: true, null: true

    Case.all.each do |kase|
      case kase.type
      when "Case::FOI"
        foi_category ||= Category.find_by! abbreviation: "FOI"
        kase.update! category_id: foi_category.id
      when "Case::SAR"
        sar_category ||= Category.find_by! abbreviation: "SAR"
        kase.update! category_id: sar_category.id
      else
        warn "Warning: type '#{kase.type}' for case #{kase.id} unrecognised, unable to reinstate category"
      end
    end
  end
end

# Ensure continuity in case this migration is ever run at a time when the
# Category model has been renamed/removed.
unless defined? Category
  class Category < ApplicationRecord
  end
end

# Ensure continuity in case this migration is ever run at a time when the
# Case models have been renamed/removed.
unless defined? Case
  class Case < ApplicationRecord
  end

  class Case::FOI < Case
  end

  class Case::SAR < Case
  end
end
