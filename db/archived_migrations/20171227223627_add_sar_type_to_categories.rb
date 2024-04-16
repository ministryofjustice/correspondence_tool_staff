class Category < ApplicationRecord
end

class AddSARTypeToCategories < ActiveRecord::Migration[5.0]
  def up
    Category.find_or_create_by! name: "Subject Access Request",
                                abbreviation: "SAR",
                                internal_time_limit: 10,
                                external_time_limit: 15,
                                escalation_time_limit: 0
    gq = Category.find_by_abbreviation("GQ")
    gq.destroy! unless gq.nil?
  end

  def down
    Category.find_by(abbreviation: "SAR").destroy
  end
end
