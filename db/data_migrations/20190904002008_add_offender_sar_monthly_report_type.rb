class AddOffenderSarMonthlyReportType < ActiveRecord::DataMigration
  def up
    ReportType.reset_column_information

    report_type = ReportType.find_by(abbr: "R205")
    report_type = ReportType.new if report_type.nil?

    report_type.update!(
      abbr: "R205",
      full_name: "Monthly report (Offender SARs)",
      class_name: "Stats::R205OffenderSarMonthlyPerformanceReport",
      custom_report: false,
      standard_report: true,
      foi: false,
      sar: false,
      offender_sar: true,
      seq_id: 600,
      default_reporting_period: "year_to_date",
      etl: false,
    )
  end
end
