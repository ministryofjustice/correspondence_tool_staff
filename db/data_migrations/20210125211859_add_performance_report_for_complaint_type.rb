class AddPerformanceReportForComplaintType < ActiveRecord::DataMigration
  def up
    ReportType.reset_column_information

    report_type = ReportType.find_by(abbr: "R206")
    report_type = ReportType.new if report_type.nil?

    report_type.update!(
      abbr: "R206",
      full_name: "Monthly report (Complaint - Standard)",
      class_name: "Stats::R206OffenderStandardComplaintMonthlyPerformanceReport",
      custom_report: true,
      standard_report: true,
      foi: false,
      sar: false,
      offender_sar: false,
      seq_id: 1200,
      default_reporting_period: "year_to_date",
      etl: false,
      offender_sar_complaint: true,
    )

    report_type = ReportType.find_by(abbr: "R207")
    report_type = ReportType.new if report_type.nil?

    report_type.update!(
      abbr: "R207",
      full_name: "Monthly report (Complaint - ICO)",
      class_name: "Stats::R207OffenderICOComplaintMonthlyPerformanceReport",
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

    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR_COMPLAINT")
    if rec.present?
      rec.update!(report_category_name: "Offender SAR Complaint")
    end
  end
end
