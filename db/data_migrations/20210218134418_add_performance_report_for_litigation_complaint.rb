class AddPerformanceReportForLitigationComplaint < ActiveRecord::DataMigration
  def up
    ReportType.reset_column_information

    report_type = ReportType.find_by(abbr: "R208")
    report_type = ReportType.new if report_type.nil?

    report_type.update!(
      abbr: "R208",
      full_name: "Monthly report (Complaint - Litigation)",
      class_name: "Stats::R208OffenderLitigationComplaintMonthlyPerformanceReport",
      custom_report: true,
      standard_report: true,
      foi: false,
      sar: false,
      offender_sar: false,
      seq_id: 1300,
      default_reporting_period: "year_to_date",
      etl: false,
      offender_sar_complaint: true,
    )
  end
end
