class AddDaysTakenAfterExtensionToWarehouseCaseReports < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_case_reports, :number_of_days_taken_after_extension, :integer        
  end
end
