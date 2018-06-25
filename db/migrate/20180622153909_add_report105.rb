class AddReport105 < ActiveRecord::Migration[5.0]
  def up
    ReportType.find_or_create_by!(abbr:'R105', full_name: 'Monthly report (SARs)', class_name: 'Stats::R105SarMonthlyPerformanceReport', custom_report: false, seq_id: 310)
  end

  def down
    ReportType.where(abbr: 'R105').destroy_all
  end
end
