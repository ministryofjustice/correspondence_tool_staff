class InitListOfReasonForDelayFieldForOffenderSar < ActiveRecord::DataMigration
  def up
    category_references = [
      {
        category: "reasons_for_lateness",
        code: "large_case_to_vet",
        value: "Large case to vet (case over 5000 pages)",
        display_order: 10,
      },
      {
        category: "reasons_for_lateness",
        code: "date_received_delay",
        value: "Data received after day 20",
        display_order: 20,
      },
      {
        category: "reasons_for_lateness",
        code: "other",
        value: "Other",
        display_order: 30,
      },
    ]

    category_references.each do |category_reference|
      CategoryReference.create(category_reference)
    end
  end

  def down
    CategoryReference.where(category: "reason_for_lateness").delete_all
  end
end
