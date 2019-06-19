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
           :date_of_birth,
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
           :received_date,
           :reply_method,
           :creator,
           :send_by_post?,
           :send_by_email?,
           :foo,
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
      params = params.merge "date_of_birth": "" unless params["date_of_birth"].present?
      params = params.merge "flag_for_disclosure_specialists": "" unless params["flag_for_disclosure_specialists"].present?
    end

    if current_step == "requester-details"
      params = params.merge "third_party": "" unless params["third_party"].present?
      params.delete "name" unless params["third_party"] == "true"
      params.delete "third_party_relationship" unless params["third_party"] == "true"
      params = params.merge "reply_method": "" unless params["reply_method"].present?
      params.delete "email" unless params["reply_method"] == "send_by_email"
      params.delete "postal_address" unless params["reply_method"] == "send_by_post"
    end

    @case.valid_attributes?(params)
  end

  def subject_type
    object.subject_type
  end

  private

  def build_case_from_session
    values = @session[:offender_sar_state] || {}
    # values = values.merge subject_type: "offender" unless values["subject_type"].present?
    # values = values.merge flag_for_disclosure_specialists: "no" unless values["flag_for_disclosure_specialists"].present?
    @case = Case::SAR::Offender.new(values).decorate
  end
end
