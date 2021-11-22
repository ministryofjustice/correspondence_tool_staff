module SarInternalReviewFormValidators 
  extend ActiveSupport::Concern

  private

  def validate_case_details(params)
    set_empty_value_if_unset(params, "subject_type")
    set_flag_for_disclosure_specialists(params)
    object.assign_attributes(params)
    # object.validate_third_party_relationship
    # object.validate_third_party_address
    # object.validate_request_dated
    # object.validate_received_date
  end

  def set_flag_for_disclosure_specialists(params)
    params.merge!('flag_for_disclosure_specialists' => 'yes')
  end

  def set_empty_value_if_unset(params, field)
    params.merge!(field => "") unless params[field].present?
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
