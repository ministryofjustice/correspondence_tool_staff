class AddClosedCasesReportForOffenderSAR < ActiveRecord::DataMigration
  def up
    rt = ReportType.find_by(abbr: "R401")
    rt = ReportType.new if rt.nil?
    rt.update!(
      abbr: "R401",
      full_name: "Closed cases report",
      class_name: "Stats::R401OffenderSARClosedCasesReport",
      custom_report: true,
      foi: false,
      sar: false,
      offender_sar: true,
      default_reporting_period: "last_month",
      etl: true,
      seq_id: 900,
    )

    rt = ReportType.find_by(abbr: "R007")
    unless rt.nil?
      rt.update!(full_name: "Closed cases report")
    end

    rt = ReportType.find_by(abbr: "R005")
    unless rt.nil?
      rt.update!(full_name: "Monthly report (FOI)")
    end

    rt = ReportType.find_by(abbr: "R105")
    unless rt.nil?
      rt.update!(full_name: "Monthly report (SAR)")
    end
  end
end
