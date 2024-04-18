class AddR50xReportTypes < ActiveRecord::DataMigration
  def up
    rt1 = ReportType.find_by(abbr: "R501")
    rt2 = ReportType.find_by(abbr: "R502")

    if rt1.nil?
      ReportType.create!(
        abbr: "R501",
        full_name: "Retention Report",
        class_name: "Stats::R501OffenderSARRetentionReport",
        custom_report: true,
        seq_id: 1000,
        offender_sar: true,
      )
    end

    if rt2.nil?
      ReportType.create!(
        abbr: "R502",
        full_name: "Retention Report",
        class_name: "Stats::R502OffenderSARComplaintRetentionReport",
        custom_report: true,
        seq_id: 1050,
        offender_sar_complaint: true,
      )
    end
  end

  def down
    ReportType.find_by_abbr!("R501").destroy!
    ReportType.find_by_abbr!("R502").destroy!
  end
end
