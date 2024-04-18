class RemoveSARIrFromCtMenu < ActiveRecord::DataMigration
  def up
    rec = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    rec.update!(show_on_menu: false)
  end

  def down
    rec = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    rec.update!(show_on_menu: true)
  end
end
