class AddReport105 < ActiveRecord::DataMigration
  def up
    rt = ReportType.find_by(abbr: "R105")
    rt = ReportType.new if rt.nil?
    rt.update!(
      abbr: "R105",
      full_name: "Monthly report",
      class_name: "Stats::R105SarMonthlyPerformanceReport",
      custom_report: true,
      foi: false,
      sar: true,
      seq_id: 310,
    )
  end
end
