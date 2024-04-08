class ModifyOffenderSARName < ActiveRecord::DataMigration
  def up
    CorrespondenceType.where(abbreviation: "OFFENDER_SAR").update(name: "Offender subject access request")
  end

  def down
    CorrespondenceType.where(abbreviation: "OFFENDER_SAR").update(name: "Offender SAR (OFFENDER)")
  end
end
