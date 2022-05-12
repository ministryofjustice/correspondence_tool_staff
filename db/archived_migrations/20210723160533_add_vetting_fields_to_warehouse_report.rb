class AddVettingFieldsToWarehouseReport < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_case_reports, :user_dealing_with_vetting, :string        
    add_column :warehouse_case_reports, :user_id_dealing_with_vetting, :integer        
    add_column :warehouse_case_reports, :number_of_days_for_vetting, :integer        
  end
end
