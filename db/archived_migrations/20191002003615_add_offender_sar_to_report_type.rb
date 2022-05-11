class AddOffenderSarToReportType < ActiveRecord::Migration[5.0]
  def change
    add_column :report_types, :offender_sar, :boolean, default: false
  end
end
