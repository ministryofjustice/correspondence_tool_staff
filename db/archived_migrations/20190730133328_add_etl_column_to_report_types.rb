class AddEtlColumnToReportTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :report_types, :etl, :boolean, default: false
  end
end
