class UpdateReportTypeNames < ActiveRecord::DataMigration
  def up
    rt1 = ReportType.find_by(abbr: "R102")
    rt2 = ReportType.find_by(abbr: "R103")
    rt3 = ReportType.find_by(abbr: "R205")
    rt4 = ReportType.find_by(abbr: "R901")
    rt5 = ReportType.find_by(abbr: "R401")
    rt6 = ReportType.find_by(abbr: "R105")
    rt7 = ReportType.find_by(abbr: "R402")
    rt8 = ReportType.find_by(abbr: "R501")
    rt9 = ReportType.find_by(abbr: "R502")

    # rubocop:disable Rails/SkipsModelValidations
    rt1.update_attribute(:class_name, "Stats::R102SARAppealsPerformanceReport") if rt1.present?
    rt2.update_attribute(:class_name, "Stats::R103SARBusinessUnitPerformanceReport") if rt2.present?
    rt3.update_attribute(:class_name, "Stats::R205OffenderSARMonthlyPerformanceReport") if rt3.present?
    rt4.update_attribute(:class_name, "Stats::R901OffenderSARCasesReport") if rt4.present?
    rt5.update_attribute(:class_name, "Stats::R401OffenderSARClosedCasesReport") if rt5.present?
    rt6.update_attribute(:class_name, "Stats::R105SARMonthlyPerformanceReport") if rt6.present?
    rt7.update_attribute(:class_name, "Stats::R402OffenderSARComplaintClosedCasesReport") if rt7.present?
    rt8.update_attribute(:class_name, "Stats::R501OffenderSARRetentionReport") if rt8.present?
    rt9.update_attribute(:class_name, "Stats::R502OffenderSARComplaintRetentionReport") if rt9.present?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    rt1 = ReportType.find_by(abbr: "R102")
    rt2 = ReportType.find_by(abbr: "R103")
    rt3 = ReportType.find_by(abbr: "R205")
    rt4 = ReportType.find_by(abbr: "R901")
    rt5 = ReportType.find_by(abbr: "R401")
    rt6 = ReportType.find_by(abbr: "R105")
    rt7 = ReportType.find_by(abbr: "R402")
    rt8 = ReportType.find_by(abbr: "R501")
    rt9 = ReportType.find_by(abbr: "R502")

    # rubocop:disable Rails/SkipsModelValidations
    rt1.update_attribute(:class_name, "Stats::R102SarAppealsPerformanceReport") if rt1.present?
    rt2.update_attribute(:class_name, "Stats::R103SarBusinessUnitPerformanceReport") if rt2.present?
    rt3.update_attribute(:class_name, "Stats::R205OffenderSarMonthlyPerformanceReport") if rt3.present?
    rt4.update_attribute(:class_name, "Stats::R901OffenderSarCasesReport") if rt4.present?
    rt5.update_attribute(:class_name, "Stats::R401OffenderSarClosedCasesReport") if rt5.present?
    rt6.update_attribute(:class_name, "Stats::R105SarMonthlyPerformanceReport") if rt6.present?
    rt7.update_attribute(:class_name, "Stats::R402OffenderSarComplaintClosedCasesReport") if rt7.present?
    rt8.update_attribute(:class_name, "Stats::R501OffenderSarRetentionReport") if rt8.present?
    rt9.update_attribute(:class_name, "Stats::R502OffenderSarComplaintRetentionReport") if rt9.present?
    # rubocop:enable Rails/SkipsModelValidations
  end
end
