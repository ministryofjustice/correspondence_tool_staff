class AddSarTypeToCategories < ActiveRecord::Migration[5.0]
  def up
    Category.find_or_create_by! name: 'Subject Access Request',
                                  abbreviation: 'SAR',
                                  internal_time_limit: 10,
                                  external_time_limit: 20,
                                  escalation_time_limit: 3
  end

  def down
    Category.find_by(abbreviation: 'SAR').destroy
  end
end
