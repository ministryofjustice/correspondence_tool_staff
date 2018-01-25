class AddR006ToReportTypes < ActiveRecord::Migration[5.0]
  def up
    ReportType.find_or_create_by!(abbr:'R006', full_name: 'KILO map', class_name: 'Stats::R006KiloMap', custom_report: false, seq_id: 9999)
  end

  def down
    ReportType.find_by_abbr!('R006').destroy
  end
end
