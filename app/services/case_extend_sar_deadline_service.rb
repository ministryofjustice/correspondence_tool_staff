class CaseExtendSARDeadlineService
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
      if valid?
        @case.state_machine.extend_sar_deadline!(
          acting_user: @user,
          acting_team: @user.team_for_case(@case),
          final_deadline: @extension_deadline,
          original_final_deadline: @case.external_deadline,
          message: message
        )

        @case.extend_deadline!(@extension_deadline)
        @result = :ok
      else
        @result = :validation_error
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
    if @case.deadline_extended?
      @case.external_deadline + extend_by.days
    else
      @case.initial_deadline + extend_by.days
    end
  end

  def message
    "#{@reason}\nDeadline extended by #{@extension_days} days"
  end

  def valid?
    validate_extension_reason
    validate_extension_deadline

    @case.errors.empty?
  end

  def validate_extension_deadline
    extension_limit = @case.max_allowed_deadline_date

    if @extension_days.blank?
      @case.errors.add(
        :extension_period,
        "can't be blank"
      )
    elsif @extension_deadline > extension_limit
      @case.errors.add(
        :extension_period,
        "can't be more than #{Settings.sar_extension_limit} days beyond the initial deadline"
      )
    elsif @extension_deadline < @case.external_deadline
      @case.errors.add(
        :extension_period,
        "can't be before the final deadline"
      )
    end
  end

  def validate_extension_reason
    if @reason.blank?
      @case.errors.add(
        :reason_for_extending,
        "can't be blank"
      )
    end
  end
end
