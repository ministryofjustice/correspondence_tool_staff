class AddClosedCasesReportType < ActiveRecord::DataMigration
  def up
    ReportType.reset_column_information

    report_type = ReportType.find_by(abbr: "R007")
    report_type = ReportType.new if report_type.nil?

    report_type.update!(
      abbr: "R007",
      full_name: "Closed cases report",
      class_name: "Stats::R007ClosedCasesReport",
      custom_report: true,
      standard_report: false,
      foi: false,
      sar: false,
      seq_id: 500,
      default_reporting_period: "last_month",
    )
  end
end
