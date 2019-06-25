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
           :received_date,
           :reply_method,
           :send_by_email?,
           :send_by_post?,
           :subject_aliases,
           :subject_full_name,
           :subject_type,
           :third_party_relationship,
           :third_party,
           :type_abbreviation,
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
    params ||= ActionController::Parameters.new({}).permit!
    params = params_for_step(params, current_step)
    @case.valid_attributes?(params)
  end

  def subject_type
    object.subject_type
  end

  private

  def params_for_step(params, step) # rubocop:disable Metrics/CyclomaticComplexity
    case step
    when "subject-details"
      params.merge!("subject_type" => "") unless params["subject_type"].present?
      params.merge!("date_of_birth" => "") unless params["date_of_birth"].present?
      params.merge!("flag_for_disclosure_specialists" => "") unless params["flag_for_disclosure_specialists"].present?
    when "requester-details"
      params.merge!("third_party": "") unless params["third_party"].present?
      params.delete("name") unless params["third_party"] == "true"
      params.delete("third_party_relationship") unless params["third_party"] == "true"

      params.merge!("reply_method": "") unless params["reply_method"].present?
      params.delete("email") unless params["reply_method"] == "send_by_email"
      params.delete("postal_address") unless params["reply_method"] == "send_by_post"
    when "date-received"
      params.merge!("received_date" => "") unless params["received_date"].present?
    end

    params
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
