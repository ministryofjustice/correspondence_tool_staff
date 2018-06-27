class AddCorrespondenceTypeColumnsToReportTypes < ActiveRecord::Migration[5.0]
  require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')

  def up
    add_column :report_types, :foi, :boolean, default: false
    add_column :report_types, :sar, :boolean, default: false
    ReportType.reset_column_information
    ReportTypeSeeder.new.seed!
  end

  def down
    remove_column :report_types, :foi, :boolean
    remove_column :report_types, :sar, :boolean
  end
end
