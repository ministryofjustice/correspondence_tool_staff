class OffenderSARCaseForm
  include ActiveModel::Model
  include Steppable

  delegate :creator,
           :date_of_birth_dd,
           :date_of_birth_mm,
           :date_of_birth_yyyy,
           :date_of_birth,
           :email,
           :errors,
           :flag_as_high_profile,
           :id,
           :message,
           :pretty_type,
           :name,
           :number,
           :object,
           :other_subject_ids,
           :postal_address,
           :previous_case_numbers,
           :prison_number,
           :received_date_dd,
           :received_date_mm,
           :received_date_yyyy,
           :received_date,
           :reply_method,
           :send_by_email?,
           :send_by_post?,
           :subject_aliases,
           :subject_full_name,
           :subject_type,
           :third_party_relationship,
           :third_party_reference,
           :third_party_company_name,
           :third_party,
           :type_abbreviation,
           to: :@case

  attr_reader :case, :session

  def initialize(session)
    if session.is_a? Case::SAR::Offender
      @case = session
      @session = {}
    else
      @session = session
      build_case_from_session
    end
  end

  # @todo: Should these steps be defined in 'Steppable' or the controller
  def steps
    %w[subject-details requester-details requested-info date-received].freeze
  end

  # @todo: Used in partial - should be decorator
  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end

  def save
    return unless valid?
    @case.save
    true # @todo: Force true for now?
  end

  def session_persist_state(params)
    @session[:offender_sar_state] ||= {}
    params ||= {}
    @session[:offender_sar_state] = @session[:offender_sar_state].merge params
  end

  def assign_params(params)
    params ||= {}
    @case.assign_attributes(params)
  end

  def valid?
    # [@case].map(&:valid?).all? && super
    @case.valid? # && super
  end

  def valid_attributes?(params)
    params ||= ActionController::Parameters.new({}).permit!
    params = params_for_step(params, current_step)
    check_valid_dates_for_step(current_step)
    @case.valid_attributes?(params)
  end

  def subject_type
    object.subject_type
  end

  private

  def check_valid_dates_for_step(step)
    @case.validate_date_of_birth if step == "subject-details"
    @case.validate_received_date if step == "date-received"
  end

  def params_for_step(params, step)
    # We partially validate each step of the form using the model validations
    # So in each step we need to ensure default values for certain fields
    # and/or conditionally clear other fields depending on related values
    case step
    when "subject-details"
      set_empty_value_if_unset(params, "subject_type")
      set_empty_value_if_unset(params, "date_of_birth")
      set_empty_value_if_unset(params, "flag_as_high_profile")
    when "requester-details"
      set_empty_value_if_unset(params, "third_party")
      clear_param_if_condition(params, "name", "third_party", "true")
      clear_param_if_condition(params, "third_party_relationship", "third_party", "true")

      set_empty_value_if_unset(params, "reply_method")
      clear_param_if_condition(params, "email", "reply_method", "send_by_email")
      clear_param_if_condition(params, "postal_address", "reply_method", "send_by_post")
    when "requested-info"
      # no tweaking needed
    when "date-received"
      set_empty_value_if_unset(params, "received_date")
    end

    params
  end

  def set_empty_value_if_unset(params, field)
    params.merge!(field => "") unless params[field].present?
  end

  def clear_param_if_condition(params, target_field, check_field, value)
    params.delete(target_field) unless params[check_field] == value
  end

  def build_case_from_session
    # regarding the `{ date_of_birth: nil }` below...
    # this is needed to prevent "NoMethodError undefined method `dd' for nil:NilClass"
    # when a new Case::SAR::Offender is being created from scratch, because the field is not
    # in the list of instance variables in the model at the point that the gov_uk_date_fields
    # is adding its magic methods. This manifests when running tests or after rails server restart
    values = @session[:offender_sar_state] || { date_of_birth: nil }

    @case = Case::SAR::Offender.new(values).decorate
  end
end
