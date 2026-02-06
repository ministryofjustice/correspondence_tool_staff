class CaseExtendSARDeadlineService
  attr_reader :result, :error

  def initialize(user:, kase:, extension_period:, reason:)
    @user = user
    @case = kase
    @case = CaseExtendSARDeadlineDecorator.decorate @case
    @extension_period = extension_period
    @extension_deadline = new_extension_deadline(@extension_period.to_i)
    @reason = reason
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      if valid?
        @case.state_machine.extend_sar_deadline!(
          acting_user: @user,
          acting_team: @user.case_team(@case),
          final_deadline: @extension_deadline,
          original_final_deadline: @case.external_deadline,
          message:,
        )
        new_extended_times = @extension_period.to_i + (@case.extended_times || 0)
        @case.extend_deadline!(@extension_deadline, new_extended_times)
        @result = :ok
      else
        @result = :validation_error
      end
    end
    @result
  rescue StandardError => e
    Rails.logger.error e.to_s
    Rails.logger.error e.backtrace.join("\n\t")
    @error = e
    @result = :error
  end

private

  def new_extension_deadline(extend_by)
    if @case.try(:restarted_at).present?
      @case.deadline_calculator.extension_deadline(extend_by) { @case.external_deadline }
    else
      @case.deadline_calculator.extension_deadline((@case.extended_times || 0) + extend_by)
    end
  end

  def message
    "#{@reason}\nDeadline extended by #{@case.time_period_description(@extension_period.to_i)}"
  end

  def valid?
    validate_extension_reason
    validate_extension_deadline

    @case.errors.empty?
  end

  def validate_extension_deadline
    extension_limit = @case.max_allowed_deadline_date

    if @extension_period.blank?
      @case.errors.add(
        :extension_period,
        "cannot be blank",
      )
    elsif @extension_deadline > extension_limit
      @case.errors.add(
        :extension_period,
        "cannot be more than #{@case.time_period_description(@case.extension_time_limit)} beyond the received date or last paused date",
      )
    elsif @extension_deadline < @case.external_deadline
      @case.errors.add(
        :extension_period,
        "cannot be before the final deadline",
      )
    end
  end

  def validate_extension_reason
    if @reason.blank?
      @case.errors.add(
        :reason_for_extending,
        "cannot be blank",
      )
    end
  end
end
