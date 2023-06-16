class FixSeqIdForLitigationPerfReport < ActiveRecord::DataMigration
  def up
    ReportType.reset_column_information

    report_type = ReportType.find_by(abbr: "R208")
    if report_type
      report_type.update!(seq_id: 1400)
    end
  end
end
