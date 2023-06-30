class RemoveSpecificReportFromSarIr < ActiveRecord::DataMigration
  def up
    ct = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    if ct.present?
      ct.report_category_name = ""
      ct.save!
    end
  end

  def down
    ct = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    if ct.present?
      ct.report_category_name = "SAR report"
      ct.save!
    end
  end
end
