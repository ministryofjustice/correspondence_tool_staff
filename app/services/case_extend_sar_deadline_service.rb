class CaseExtendSARDeadlineService
  attr_reader :result, :error

  def initialize(user:, kase:, extension_period:, reason:)
    @user = user
    @case = kase
    @case = CaseExtendSARDeadlineDecorator.decorate @case
    @extension_period = extension_period
    @extension_deadline = @case.new_extension_deadline(@extension_period.to_i)
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

        new_months_extended = @extension_period.to_i + (@case.months_extended || 0)
        @case.extend_deadline!(@extension_deadline, new_months_extended)
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

  def message
    [
      @reason,
      "Deadline extended by #{@case.time_period_description(@extension_period.to_i)}\n",
      "Old final deadline: #{I18n.localize(@case.external_deadline, format: :long)}",
      "New final deadline: #{I18n.localize(@extension_deadline, format: :long)}",
    ].join("\n")
  end

  def valid?
    validate_extension_reason
    validate_extension_deadline

    @case.errors.empty?
  end

  def validate_extension_deadline
    if @extension_period.blank?
      @case.errors.add(
        :extension_period,
        "cannot be blank",
      )
    elsif @extension_deadline < @case.external_deadline
      @case.errors.add(
        :extension_period,
        "cannot be before the final deadline",
      )
    elsif invalid_extension_period?
      @case.errors.add(
        :extension_period,
        invalid_extension_period_message,
      )
    end
  end

  # Fixed-extension types (Standard/Offender SAR) may only be extended by the
  # single fixed period; legacy types are capped at a cumulative limit.
  def invalid_extension_period?
    if @case.fixed_extension?
      @extension_period.to_i != @case.extension_fixed_period
    else
      (@case.months_extended.to_i + @extension_period.to_i) > @case.extension_time_limit
    end
  end

  def invalid_extension_period_message
    if @case.fixed_extension?
      "must be #{@case.time_period_description(@case.extension_fixed_period)}"
    else
      "cannot be more than #{@case.time_period_description(@case.extension_time_limit)} beyond the received date or last paused date"
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
