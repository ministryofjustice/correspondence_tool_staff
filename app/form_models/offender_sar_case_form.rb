class OffenderSARCaseForm
  include ActiveModel::Model
  include Steppable

  delegate  :creator,
            :date_of_birth_dd,
            :date_of_birth_mm,
            :date_of_birth_yyyy,
            :email,
            :errors,
            :flag_for_disclosure_specialists,
            :id,
            :message,
            :message,
            :name,
            :name,
            :object,
            :other_subject_ids,
            :postal_address,
            :previous_case_numbers,
            :prison_number,
            :received_date_dd,
            :received_date_mm,
            :received_date_yyyy,
            :reply_method,
            :send_by_email?,
            :send_by_post?,
            :subject_aliases,
            :subject_full_name,
            :subject_type,
            :third_party,
            :third_party_relationship,
            :type_abbreviation,
            to: :@case

  attr_reader :case

  def initialize(session)
    @session = session
    build_case_from_session
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
    params ||= {}
    @case.valid_attributes?(params)
  end

  private

  def build_case_from_session
    values = @session[:offender_sar_state] || {}
    @case = Case::SAR::Offender.new(values).decorate
  end
end
