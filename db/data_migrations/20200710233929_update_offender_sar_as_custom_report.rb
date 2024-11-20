class UpdateOffenderSARAsCustomReport < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.find_each do |ct|
      next unless ct.abbreviation == "OFFENDER_SAR"

      ct.update!(
        report_category_name: "Offender SAR",
      )
    end

    ReportType.offender_sar.each do |report_type|
      report_type.update(
        custom_report: true,
        offender_sar: true,
      )
    end
  end

  def down
    CorrespondenceType.all.find_each do |ct|
      next unless ct.abbreviation == "OFFENDER_SAR"

      ct.update!(
        report_category_name: "",
      )
    end
    ReportType.offender_sar.each do |report_type|
      report_type.update(
        custom_report: false,
        offender_sar: false,
      )
    end
  end
end
