class AddSarAppealsReport < ActiveRecord::Migration[5.0]
  require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')

  def up
    ReportType.find_or_create_by!(abbr:'R102', full_name: 'Appeals performance report(SARs)', class_name: 'Stats::R102SarAppealsPerformanceReport', custom_report: true, foi: false, sar: true, seq_id: 320)
    ReportTypeSeeder.new.seed!
  end

  def down
    ReportType.where(abbr: 'R102').destroy_all
  end
end
