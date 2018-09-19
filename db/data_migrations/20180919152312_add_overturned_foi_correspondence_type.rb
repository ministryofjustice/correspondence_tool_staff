class AddOverturnedFoiCorrespondenceType < ActiveRecord::DataMigration
  def up
    CorrespondenceType.create!(
        name:                       'Overturned ICO appeal (FOI)',
        abbreviation:               'OVERTURNED_FOI',
        internal_time_limit:        10,
        external_time_limit:        20,
        escalation_time_limit:      3,
        deadline_calculator_class:  'BusinessDays',
        default_private_officer:    "correspondence-staff-dev+primrose.offord@digital.justice.gov.uk",
        default_press_officer:      "correspondence-staff-dev+preston.offman@digital.justice.gov.uk",
        report_category_name:       ''
    )
  end
end
