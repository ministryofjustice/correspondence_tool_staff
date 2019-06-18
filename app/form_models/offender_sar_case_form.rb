class OffenderSARCaseForm
  include ActiveModel::Model
  include Steppable

  delegate :id,
           :name,
           :email,
           :message,
           :type_abbreviation,
           :object,
           :errors,
           :subject_full_name,
           :prison_number,
           :subject_aliases,
           :previous_case_numbers,
           :other_subject_ids,
           :date_of_birth_dd,
           :date_of_birth_mm,
           :date_of_birth_yyyy,
           :subject_type,
           :flag_for_disclosure_specialists,
           :third_party,
           :name,
           :third_party_relationship,
           :postal_address,
           :message,
           :received_date_dd,
           :received_date_mm,
           :received_date_yyyy,
           :reply_method,
           :creator,
           :send_by_post?,
           :send_by_email?,
           to: :@case

  attr_reader :case

  def initialize(session)
    @session = session
    build_case_from_session
  end

  def steps
    %w[subject-details requester-details requested-info date-received].freeze
  end

  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end

  def save
    return unless valid?
    @case.save
    true
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
    if current_step == "subject-details"
      params = params.merge "subject_type": "" unless params["subject_type"].present?
    end
    @case.valid_attributes?(params)
  end

  def subject_type
    object.subject_type
  end

  private

  def build_case_from_session
    values = @session[:offender_sar_state] || {}
    values = values.merge subject_type: "offender" unless values["subject_type"].present?
    values = values.merge flag_for_disclosure_specialists: "no" unless values["flag_for_disclosure_specialists"].present?
    @case = Case::SAR::Offender.new(values).decorate
  end
end
