module OffenderSARCaseForm
  extend ActiveSupport::Concern

  # @todo: Should these steps be defined in 'Steppable' or the controller
  def steps
    %w[subject-details
       requester-details
       recipient-details
       requested-info
       request-details
       date-received].freeze
  end

  def valid_attributes?(params)
    params ||= ActionController::Parameters.new({}).permit!
    params = params_for_step(params, current_step)
    object.assign_attributes(params)
    check_custom_validations_for_step(current_step)
    object.valid_attributes?(params)
  end

  private

  def check_custom_validations_for_step(step)
    object.validate_date_of_birth if step == "subject-details"
    if step == "requester-details"
      object.validate_third_party_names
      object.validate_third_party_relationship
      object.validate_third_party_address
    end
    if step == "recipient-details"
      object.validate_recipient
      object.validate_third_party_relationship
      object.validate_third_party_address
    end
    object.validate_received_date if step == "date-received"
  end

  def params_for_step(params, step)
    # We partially validate each step of the form using the model validations
    # So in each step we need to ensure default values for certain fields
    # and/or conditionally clear other fields depending on related values
    case step
    when "subject-details"
      set_empty_value_if_unset(params, "subject_type")
      set_empty_value_if_unset_for_date(params, "date_of_birth")
      set_empty_value_if_unset(params, "flag_as_high_profile")
    when "requester-details"
      set_empty_value_if_unset(params, "third_party")
      clear_param_if_condition(params, "third_party_name", "third_party", "true")
      clear_param_if_condition(params, "third_party_company_name", "third_party", "true")
      clear_param_if_condition(params, "third_party_relationship", "third_party", "true")
      # set_empty_value_if_unset(params, "reply_method")
      # clear_param_if_condition(params, "email", "reply_method", "send_by_email")
      clear_param_if_condition(params, "postal_address", "reply_method", "send_by_post")
    when "recipient-details"
      set_empty_value_if_unset(params, "recipient")
      clear_param_if_condition(params, "postal_address", "third_party", "true")
    when "requested-info"
      # no tweaking needed
    when "date-received"
      set_empty_value_if_unset_for_date(params, "received_date")
    end

    params
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
