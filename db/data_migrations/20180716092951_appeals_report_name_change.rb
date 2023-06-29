class AppealsReportNameChange < ActiveRecord::DataMigration
  def up
    report_type = ReportType.find_by(abbr: "R002")
    report_type.update!(full_name: "Appeals report (FOI)")
  end

  def down
    report_type = ReportType.find_by(abbr: "R002")
    report_type.update!(full_name: "Appeals performance report")
  end
end
