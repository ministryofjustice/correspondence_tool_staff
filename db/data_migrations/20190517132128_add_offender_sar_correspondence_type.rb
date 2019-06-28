class AddOffenderSarCorrespondenceType < ActiveRecord::DataMigration
  def up
    CorrespondenceType.create!(
      name:                       'Offender SAR',
      abbreviation:               'OFFENDER_SAR',
      internal_time_limit:        10,
      external_time_limit:        30,
      escalation_time_limit:      3,
      deadline_calculator_class:  'CalendarDays',
      default_private_officer:    "correspondence-staff-dev+primrose.offord@digital.justice.gov.uk",
      default_press_officer:      "correspondence-staff-dev+preston.offman@digital.justice.gov.uk",
      report_category_name:       'Offender SAR report'
    )
  end
end
