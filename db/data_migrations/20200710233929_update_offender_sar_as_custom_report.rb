class UpdateOffenderSarAsCustomReport < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'OFFENDER_SAR'
        ct.update_attributes(
          report_category_name: "Offender SAR"
        )
      end
    end

    ReportType.offender_sar.each do |report_type|
      report_type.update_attributes(
        custom_report: true,
        offender_sar: true
      )
    end
  end

  def down
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'OFFENDER_SAR'
        ct.update_attributes(
          report_category_name: ""
        )  
      end
    end
    ReportType.offender_sar.each do |report_type|
      report_type.update_attributes(
        custom_report: false,
        offender_sar: false
      )
    end
  end
end
