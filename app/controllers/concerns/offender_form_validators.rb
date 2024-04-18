module OffenderFormValidators
  extend ActiveSupport::Concern

private

  def validate_subject_details(params)
    set_empty_value_if_unset(params, "subject_type")
    set_empty_value_if_unset_for_date(params, "date_of_birth")
    set_empty_value_if_unset(params, "flag_as_high_profile")
    object.assign_attributes(params)
    object.validate_date_of_birth
  end

  def validate_complaint_type(params)
    set_empty_value_if_unset(params, "complaint_type")
    set_empty_value_if_unset(params, "complaint_subtype")
    set_empty_value_if_unset(params, "priority")
    object.assign_attributes(params)
    object.validate_ico_contact_name
    object.validate_ico_contact_details
    object.validate_ico_reference
    object.validate_gld_contact_name
    object.validate_gld_contact_details
    object.validate_gld_reference
  end

  def validate_requester_details(params)
    set_empty_value_if_unset(params, "third_party")
    clear_param_if_condition(params, "third_party_name", "third_party", "true")
    clear_param_if_condition(params, "third_party_company_name", "third_party", "true")
    clear_param_if_condition(params, "third_party_relationship", "third_party", "true")
    clear_param_if_condition(params, "third_party_email", "third_party", "true")

    object.assign_attributes(params)

    object.validate_third_party_names
    object.validate_third_party_relationship
    object.validate_third_party_address
    object.validate_third_party_email_format
  end

  def validate_recipient_details(params)
    set_empty_value_if_unset(params, "recipient")
    object.assign_attributes(params)
    object.validate_recipient
    object.validate_third_party_relationship
    object.validate_third_party_address
  end

  def validate_request_details(params)
    object.assign_attributes(params)
    object.validate_request_dated
  end

  def validate_date_received(params)
    set_empty_value_if_unset_for_date(params, "received_date")
    set_empty_value_if_unset(params, "request_method") unless object.offender_sar_complaint?
    object.assign_attributes(params)
    object.validate_received_date
  end

  def validate_reason_rejected(params)
    object.assign_attributes(params)
    object.validate_rejected_reason
  end

  def set_empty_value_if_unset(params, field)
    params.merge!(field => "") if params[field].blank?
  end

  def set_empty_value_if_unset_for_date(params, field)
    params.merge!(field => "") unless params["#{field}_yyyy"].present? &&
      params["#{field}_mm"].present? &&
      params["#{field}_dd"].present?
  end

  def clear_param_if_condition(params, target_field, check_field, value)
    params.delete(target_field) unless params[check_field] == value
  end
end
