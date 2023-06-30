class BypassParamsManager
  attr_reader :error_message, :params

  def initialize(params)
    @params             = params
    @error_message      = nil
    @present            = @params[:bypass_approval].present?
    @valid              = present? && params_valid?
    @approval_requested = present? && check_approval_requested?
  end

  def present?
    @present
  end

  def valid?
    present? && @valid
  end

  def approval_requested?
    @valid && @approval_requested
  end

  def bypass_requested?
    !@approval_requested
  end

  def message
    @params[:bypass_approval][:bypass_message]
  end

  def ==(other)
    @params == other.params
  end

private

  def check_approval_requested?
    @params[:bypass_approval][:press_office_approval_required] == "true"
  end

  def check_bypass_requested?
    !check_approval_requested?
  end

  def params_valid?
    if present? && check_approval_requested? && check_message_present?
      record_error "Do not specify a reason for skipping further clearance if further clearance required."
    elsif present? && check_bypass_requested? && check_message_blank?
      record_error "You must specify a reason for skipping further clearance"
    else
      true
    end
  end
  # rubocop:ensable Metrics/CyclomaticComplexity

  def record_error(message)
    @error_message = message
    false
  end

  def check_message_present?
    @params[:bypass_approval][:bypass_message].present?
  end

  def check_message_blank?
    !check_message_present?
  end
end
