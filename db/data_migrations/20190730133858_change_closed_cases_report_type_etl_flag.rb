class ChangeClosedCasesReportTypeEtlFlag < ActiveRecord::DataMigration
  def up
    closed_cases_report_type = ReportType.find_by(abbr: "R007")
    if closed_cases_report_type
      closed_cases_report_type.update!(etl: true)
    end
  end

  def down
    closed_cases_report_type = ReportType.find_by(abbr: "R007")
    if closed_cases_report_type
      closed_cases_report_type.update!(etl: false)
    end
  end
end
