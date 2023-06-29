class CorrespondenceTypeSeeder
  def seed!
    Rails.logger.debug "----Seeding Correspondence Types----"

    rec = CorrespondenceType.find_by(abbreviation: "FOI")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Freedom of information request",
                abbreviation: "FOI",
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                show_on_menu: true,
                report_category_name: "FOI report",
                deadline_calculator_class: "BusinessDays",
                default_press_officer: "correspondence-staff-dev+preston.offman@digital.justice.gov.uk",
                default_private_officer: "correspondence-staff-dev+primrose.offord@digital.justice.gov.uk",
                display_order: 0)

    rec = CorrespondenceType.find_by(abbreviation: "SAR")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Subject Access request",
                abbreviation: "SAR",
                show_on_menu: true,
                report_category_name: "SAR report",
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 1,
                extension_time_limit: 2,
                extension_time_default: 1,
                deadline_calculator_class: "CalendarMonths",
                default_press_officer: "correspondence-staff-dev+preston.offman@digital.justice.gov.uk",
                default_private_officer: "correspondence-staff-dev+primrose.offord@digital.justice.gov.uk",
                display_order: 1)

    rec = CorrespondenceType.find_by(abbreviation: "ICO")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Information commissioner office appeal",
                abbreviation: "ICO",
                show_on_menu: true,
                report_category_name: "",
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 30,
                deadline_calculator_class: "BusinessDays",
                display_order: 3)

    rec = CorrespondenceType.find_by(abbreviation: "OVERTURNED_SAR")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Overturned ICO appeal (SAR)",
                abbreviation: "OVERTURNED_SAR",
                show_on_menu: false,
                report_category_name: "",
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 30,
                deadline_calculator_class: "CalendarDays",
                display_order: nil)

    rec = CorrespondenceType.find_by(abbreviation: "OVERTURNED_FOI")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Overturned ICO appeal (FOI)",
                abbreviation: "OVERTURNED_FOI",
                show_on_menu: false,
                report_category_name: "",
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                deadline_calculator_class: "BusinessDays",
                default_press_officer: "correspondence-staff-dev+preston.offman@digital.justice.gov.uk",
                default_private_officer: "correspondence-staff-dev+primrose.offord@digital.justice.gov.uk",
                display_order: nil)

    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Offender subject access request",
                abbreviation: "OFFENDER_SAR",
                show_on_menu: true,
                report_category_name: "Offender SAR",
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 1,
                extension_time_limit: 2,
                extension_time_default: 1,
                deadline_calculator_class: "CalendarMonths",
                display_order: nil)

    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR_COMPLAINT")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Offender subject access request complaint",
                abbreviation: "OFFENDER_SAR_COMPLAINT",
                show_on_menu: true,
                report_category_name: "Offender SAR Complaint",
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                deadline_calculator_class: "BusinessDays",
                display_order: nil)

    rec = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Subject access request internal review",
                abbreviation: "SAR_INTERNAL_REVIEW",
                show_on_menu: false,
                report_category_name: "",
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 1,
                extension_time_limit: 2,
                extension_time_default: 1,
                deadline_calculator_class: "CalendarMonths",
                default_press_officer: "correspondence-staff-dev+preston.offman@digital.justice.gov.uk",
                default_private_officer: "correspondence-staff-dev+primrose.offord@digital.justice.gov.uk",
                display_order: 2)
  end
end
