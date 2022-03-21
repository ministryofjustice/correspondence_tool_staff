class AddOriginalDeadlineFieldsToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_case_reports, :original_external_deadline, :date        
    add_column :warehouse_case_reports, :original_internal_deadline, :date        
    add_column :warehouse_case_reports, :num_days_late_against_original_deadline, :integer        
  end
end
