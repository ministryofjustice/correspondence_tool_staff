module OffenderFormValidators
  extend ActiveSupport::Concern

  private

  def validate_case_details(params)
    set_empty_value_if_unset(params, "subject_type")
    set_empty_value_if_unset_for_date(params, "date_of_birth")
    set_empty_value_if_unset(params, "flag_as_high_profile")
    object.assign_attributes(params)
    object.validate_date_of_birth
  end

  def validate_date_received(params)
    set_empty_value_if_unset_for_date(params, "received_date")
    object.assign_attributes(params)
    object.validate_received_date
  end

  def set_empty_value_if_unset(params, field)
    params.merge!(field => "") unless params[field].present?
  end

  def set_trigger_case_param(params, field)
    params.merge!(field => true) unless params[field].present?
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
