class AddAddressTypes < ActiveRecord::DataMigration
  def up
    category_references = [
      {
        category: "contact_type",
        code: "prison",
        value: "Prison",
        display_order: 10,
      },
      {
        category: "contact_type",
        code: "probation",
        value: "Probation centre",
        display_order: 20,
      },
      {
        category: "contact_type",
        code: "solicitor",
        value: "Solicitor",
        display_order: 30,
      },
      {
        category: "contact_type",
        code: "branston",
        value: "Branson",
        display_order: 40,
      },
      {
        category: "contact_type",
        code: "hmpps_hq",
        value: "HMPPS HQ",
        display_order: 50,
      },
      {
        category: "contact_type",
        code: "hmcts",
        value: "HMCTS",
        display_order: 60,
      },
      {
        category: "contact_type",
        code: "other",
        value: "Other",
        display_order: 70,
      },
    ]

    category_references.each do |category_reference|
      rec = CategoryReference.find_by(
        category: category_reference["category"],
        code: category_reference["code"],
      )

      rec = CategoryReference.new if rec.nil?

      rec.update!(category_reference)
    end
  end

  def down
    CategoryReference.where(category: "contact_type").delete_all
  end
end
