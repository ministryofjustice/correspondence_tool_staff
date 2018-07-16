class AddSarAppealsReport < ActiveRecord::Migration[5.0]
  def up
    ReportType.find_or_create_by!(abbr:'R102', full_name: 'Appeals performance report(SARs)', class_name: 'Stats::R102SarAppealsPerformanceReport', custom_report: true, foi: false, sar: true, seq_id: 320)
  end

  def down
    ReportType.where(abbr: 'R102').destroy_all
  end
end
