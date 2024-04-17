class AddOffenderSARComplaintToReportType < ActiveRecord::Migration[5.2]
  def change
    add_column :report_types, :offender_sar_complaint, :boolean, default: false
  end
end
