class AddOverturnedSARCorrespondenceType < ActiveRecord::DataMigration
  def up
    CorrespondenceType.create!(
      name: "Overturned ICO appeal (SAR)",
      abbreviation: "OVERTURNED_SAR",
      internal_time_limit: 10,
      external_time_limit: 30,
      escalation_time_limit: 0,
      deadline_calculator_class: "CalendarDays",
      default_private_officer: nil,
      default_press_officer: nil,
      report_category_name: "",
    )
  end
end
