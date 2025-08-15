module OffenderSARComplaintCaseForm
  extend ActiveSupport::Concern

  include OffenderFormValidators

  STEPS = %w[link-offender-sar-case
             confirm-offender-sar
             complaint-type
             requester-details
             recipient-details
             requested-info
             request-details
             date-received
             set-deadline].freeze

  def steps
    STEPS
  end

private

  def validate_link_offender_sar_case(params)
    original_case_number = (params[:original_case_number] || "").strip
    case_link = LinkedCase.new(
      linked_case_number: original_case_number,
      type: :original,
    )
    if case_link.valid?
      original_case = case_link.linked_case
      if !Pundit.policy(object.creator, original_case).show?
        add_errors_for_original_case(
          I18n.t("activerecord.errors.models.case/sar/offender_complaint.attributes.original_case.not_authorised"),
        )
      else
        object.original_case_id = original_case.id
        object.validate_original_case
        object.validate_original_case_not_already_related
      end
    else
      add_errors_for_original_case(case_link.errors[:linked_case_number].join(". "))
    end
  end

  def add_errors_for_original_case(message)
    object.errors.add(:original_case_number, message)
  end

  def params_after_step_link_offender_sar_case(params)
    params.merge!(original_case_id: object.original_case_id)
    params.delete(:original_case_number)

    params
  end

  def params_after_step_confirm_offender_sar(params)
    params.merge!(original_case_id: object.original_case_id)
    params.delete(:original_case_number)
    fields_subject_details = %w[
      subject_full_name
      subject_type
      subject_aliases
      subject_address
      prison_number
      other_subject_ids
      recipient
      third_party_relationship
      third_party
      third_party_company_name
      third_party_name
      postal_address
      probation_area
      flag_as_high_profile
      flag_as_dps_missing_data
      date_of_birth
      email
    ]
    fields_subject_details.each do |single_field|
      params[single_field] = object.original_case.send(single_field)
    end
    params
  end

  def params_after_step_date_received(params)
    if [nil, "standard_complaint"].include? object["complaint_type"]
      params.merge!(external_deadline: object.deadline_calculator.external_deadline)
    end
    params
  end

  def validate_set_deadline(params)
    set_empty_value_if_unset_for_date(params, "external_deadline")
    object.assign_attributes(params)
    object.validate_external_deadline
  end
end
