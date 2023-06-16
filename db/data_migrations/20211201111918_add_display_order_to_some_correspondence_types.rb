class AddDisplayOrderToSomeCorrespondenceTypes < ActiveRecord::DataMigration
  def up
    # put your code here
    rec = CorrespondenceType.find_by(abbreviation: "FOI")
    rec.update!(display_order: 0) if rec

    rec = CorrespondenceType.find_by(abbreviation: "SAR")
    rec.update!(display_order: 1) if rec

    rec = CorrespondenceType.find_by(abbreviation: "ICO")
    rec.update!(display_order: 3) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OVERTURNED_SAR")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OVERTURNED_FOI")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR_COMPLAINT")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    rec.update!(display_order: 2) if rec
  end

  def down
    # put your code here
    rec = CorrespondenceType.find_by(abbreviation: "FOI")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "SAR")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "ICO")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OVERTURNED_SAR")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OVERTURNED_FOI")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR_COMPLAINT")
    rec.update!(display_order: nil) if rec

    rec = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    rec.update!(display_order: nil) if rec
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
