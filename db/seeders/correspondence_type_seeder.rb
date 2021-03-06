class CorrespondenceTypeSeeder

  #rubocop:disable Metrics/MethodLength
  #rubocop:disable Metrics/CyclomaticComplexity
  def seed!
    puts "----Seeding Correspondence Types----"

    rec = CorrespondenceType.find_by(abbreviation: 'FOI')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Freedom of information request',
                abbreviation: 'FOI',
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                show_on_menu: true,
                report_category_name: 'FOI report',
                deadline_calculator_class: 'BusinessDays',
                default_press_officer: 'correspondence-staff-dev+preston.offman@digital.justice.gov.uk',
                default_private_officer: 'correspondence-staff-dev+primrose.offord@digital.justice.gov.uk')

    rec = CorrespondenceType.find_by(abbreviation: 'SAR')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Subject access request',
                abbreviation: 'SAR',
                show_on_menu: true, 
                report_category_name: 'SAR report', 
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 1,
                extension_time_limit: 2,
                extension_time_default: 1,
                deadline_calculator_class: 'CalendarMonths',
                default_press_officer: 'correspondence-staff-dev+preston.offman@digital.justice.gov.uk',
                default_private_officer: 'correspondence-staff-dev+primrose.offord@digital.justice.gov.uk')

    rec = CorrespondenceType.find_by(abbreviation: 'ICO')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Information commissioner office appeal',
                abbreviation: 'ICO',
                show_on_menu: true, 
                report_category_name: '',
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 30,
                deadline_calculator_class: 'BusinessDays')

    rec = CorrespondenceType.find_by(abbreviation: 'OVERTURNED_SAR')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Overturned ICO appeal (SAR)',
                abbreviation: 'OVERTURNED_SAR',
                show_on_menu: false, 
                report_category_name: '',
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 30,
                deadline_calculator_class: 'CalendarDays')

    rec = CorrespondenceType.find_by(abbreviation: 'OVERTURNED_FOI')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Overturned ICO appeal (FOI)',
                abbreviation: 'OVERTURNED_FOI',
                show_on_menu: false, 
                report_category_name: '',
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                deadline_calculator_class: 'BusinessDays',
                default_press_officer: 'correspondence-staff-dev+preston.offman@digital.justice.gov.uk',
                default_private_officer: 'correspondence-staff-dev+primrose.offord@digital.justice.gov.uk')

    rec = CorrespondenceType.find_by(abbreviation: 'OFFENDER_SAR')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Offender subject access request',
                abbreviation: 'OFFENDER_SAR',
                show_on_menu: true, 
                report_category_name: 'Offender SAR', 
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 1,
                extension_time_limit: 2, 
                extension_time_default: 1, 
                deadline_calculator_class: 'CalendarMonths')

    rec = CorrespondenceType.find_by(abbreviation: 'OFFENDER_SAR_COMPLAINT')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Offender subject access request complaint',
                abbreviation: 'OFFENDER_SAR_COMPLAINT',
                show_on_menu: true, 
                report_category_name: 'Offender SAR Complaint', 
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                deadline_calculator_class: 'BusinessDays')
  end
  #rubocop:enable Metrics/MethodLength
  #rubocop:enable Metrics/CyclomaticComplexity
end
