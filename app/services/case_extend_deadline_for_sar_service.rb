class CaseExtendDeadlineForSARService
  attr_reader :result, :error

  def initialize(user, kase, extension_days, reason)
    @user = user
    @case = kase
    @extension_days = extension_days
    @extension_deadline = new_extension_deadline(@extension_days.to_i)
    @reason = reason
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      if validate_params
        @case.state_machine.extend_deadline_for_sar!(
          acting_user: @user,
          acting_team: @user.team_for_case(@case),
          final_deadline: @extension_deadline,
          original_final_deadline: @case.external_deadline,
          message: message
        )

        @case.extend_deadline!(@extension_deadline)
        @result = :ok
      end
    end
    @result
  rescue => err
    Rails.logger.error err.to_s
    Rails.logger.error err.backtrace.join("\n\t")
    @error = err
    @result = :error
  end

  private

  def new_extension_deadline(extend_by)
    current_deadline =  @case.deadline_extended? ?
                          @case.external_deadline :
                          @case.initial_deadline
    current_deadline + extend_by.days
  end

  def message
    "#{@reason}\nDeadline extended by #{@extension_days} days"
  end

  def validate_params
    unless @reason.present?
      @case.errors.add(:reason_for_extending, "can't be blank")
      @result = :validation_error
    end

    unless extension_date_valid?
      @result = :validation_error
    end

    @result = :ok if @case.errors.empty?
  end

  def extension_date_valid?
    # TODO (Mohammed Seedat): Check if this rule is correct because a SAR
    # extension can be extended up to max 60 days
    extension_limit = @case.max_allowed_extension_date

    valid = false

    if @extension_days.blank? || @extension_deadline.blank?
      @case.errors.add(
        :extension_period,
        "can't be blank"
      )
    elsif @extension_deadline > extension_limit
      @case.errors.add(
        :extension_period,
        "can't be more than #{Settings.sar_extension_limit} beyond the final deadline"
      )
    elsif @extension_deadline < @case.external_deadline
      @case.errors.add(
        :extension_period,
        "can't be before the final deadline"
      )
    else
      valid = true
    end

    valid
  end
end
