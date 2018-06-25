class CorrespondenceTypeSeeder

  #rubocop:disable Metrics/MethodLength
  def seed!
    puts "----Seeding Correspondence Types----"

    rec = CorrespondenceType.find_by(abbreviation: 'FOI')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Freedom of information request',
                abbreviation: 'FOI',
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                deadline_calculator_class: 'BusinessDays',
                default_press_officer: 'correspondence-staff-dev+preston.offman@digital.justice.gov.uk',
                default_private_officer: 'correspondence-staff-dev+primrose.offord@digital.justice.gov.uk')

    rec = CorrespondenceType.find_by(abbreviation: 'SAR')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Subject access request',
                abbreviation: 'SAR',
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 30,
                deadline_calculator_class: 'CalendarDays',
                default_press_officer: 'correspondence-staff-dev+preston.offman@digital.justice.gov.uk',
                default_private_officer: 'correspondence-staff-dev+primrose.offord@digital.justice.gov.uk')

    rec = CorrespondenceType.find_by(abbreviation: 'ICO')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Information Commissioner Office appeal.',
                abbreviation: 'ICO',
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 30,
                deadline_calculator_class: 'CalendarDays')

  end
  #rubocop:enable Metrics/MethodLength
end
