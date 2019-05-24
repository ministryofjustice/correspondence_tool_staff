class OffenderSARCaseForm
  include ActiveModel::Model
  include Steppable

  delegate :id, :name, :email, :message, :type_abbreviation, :object, :errors, to: :@case
  attr_reader :case
  #validate :email_addresses_must_match

  def initialize(kase, params, session)
    @case = kase
    @params = case_params(params)
    @session = session
    foo
    self
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

  def session_persist_state
    @session[:offender_sar_state] ||= {}
    @session[:offender_sar_state].merge @params
  end

  def valid?
    # [@case].map(&:valid?).all? && super
    @case.valid? && super
  end

  def valid_params?
    valid = true
    @params.each do |param, value|
      valid = false if value.empty? # todo - can we farm this out to the model? e.g. @case.validate_attribute(param)
    end
  end

  private

  def case_params(params)
    params.require(:offender_sar_case_form).permit(:name, :email, :message) if params[:offender_sar_case_form].present?
  end

end
