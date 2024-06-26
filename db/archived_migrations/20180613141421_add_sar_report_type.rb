class AddSARReportType < ActiveRecord::Migration[5.0]
  class ReportType < ApplicationRecord
  end

  def up
    ReportType.create!(
      abbr: "R103",
      full_name: "Business unit report (SARs)",
      class_name: "Stats::R103SARBusinessUnitPerformanceReport",
      custom_report: true,
      seq_id: 250,
    )
  end

  def down
    ReportType.find_by(abbr: "R103").destroy!
  end
end
