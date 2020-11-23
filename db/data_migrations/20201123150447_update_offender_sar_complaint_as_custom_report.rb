class UpdateOffenderSarComplaintAsCustomReport < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'OFFENDER_SAR_COMPLAINT'
        ct.update_attributes(
          report_category_name: "Offender SAR complaint"
        )
      end
    end
  end

  def down
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'OFFENDER_SAR_COMPLAINT'
        ct.update_attributes(
          report_category_name: ""
        )
      end
    end
  end
end
