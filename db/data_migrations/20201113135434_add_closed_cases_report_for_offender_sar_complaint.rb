class AddClosedCasesReportForOffenderSarComplaint < ActiveRecord::DataMigration
  def up
    rt = ReportType.find_by(abbr: "R402")
    rt = ReportType.new if rt.nil?
    rt.update!(
      abbr: "R402",
      full_name: "Closed cases report",
      class_name: "Stats::R402OffenderSarComplaintClosedCasesReport",
      custom_report: true,
      foi: false,
      sar: false,
      offender_sar: false,
      offender_sar_complaint: true,
      default_reporting_period: "last_month",
      etl: true,
      seq_id: 950,
    )
  end
end
