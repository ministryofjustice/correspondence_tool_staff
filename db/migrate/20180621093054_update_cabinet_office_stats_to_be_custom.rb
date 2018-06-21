class UpdateCabinetOfficeStatsToBeCustom < ActiveRecord::Migration[5.0]
  def up
    rt = ReportType.find_by_abbr('R004')
    if rt.nil?
      ReportType.find_or_create_by!(abbr:'R004', full_name: 'Cabinet Office report', class_name: 'Stats::R004CabinetOfficeReport', custom_report: true, seq_id: 400)
    else
      rt.update custom_report: true
    end
  end

  def down
    rt = ReportType.find_by_abbr('R004')
    if rt.nil?
      ReportType.find_or_create_by!(abbr:'R004', full_name: 'Cabinet Office report', class_name: 'Stats::R004CabinetOfficeReport', custom_report: false, seq_id: 400)
    else
      rt.update custom_report: false
    end
  end
end
