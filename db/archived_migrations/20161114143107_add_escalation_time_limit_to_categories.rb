class AddEscalationTimeLimitToCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :categories, :escalation_time_limit, :integer
  end
end
