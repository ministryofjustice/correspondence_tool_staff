class AddOpenCasesReports < ActiveRecord::DataMigration
  def up
    rt = ReportType.find_by(abbr: "R901")
    rt = ReportType.new if rt.nil?
    rt.update!(
      abbr: "R901",
      full_name: "Open cases report for Offender SAR",
      class_name: "Stats::R901OffenderSARCasesReport",
      custom_report: false,
      standard_report: false,
      foi: false,
      sar: false,
      offender_sar: true,
      seq_id: 1100,
    )

    rt = ReportType.find_by(abbr: "R900")
    rt = ReportType.new if rt.nil?
    rt.update!(
      abbr: "R900",
      full_name: "Cases report",
      class_name: "Stats::R900CasesReport",
      custom_report: false,
      standard_report: false,
      foi: true,
      sar: true,
      offender_sar: false,
      seq_id: 1000,
    )
  end
end
