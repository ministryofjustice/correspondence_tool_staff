class FixBranstonContactType < ActiveRecord::DataMigration
  def up
    cat_ref = CategoryReference.find_by(
      category: "contact_type",
      code: "branston",
    )

    return unless cat_ref

    cat_ref.value = "Branston"
    cat_ref.save!
  end
end
