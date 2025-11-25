class CaseRestartTheClockService
  attr_reader :result, :error

  def initialize(user, kase, restart_the_clock_date)
    @user = user
    @case = kase
    @restart_the_clock_date = restart_the_clock_date
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      if validate_params
        last_working_state = @case.last_stop_the_clock_transition.details["last_status"]

        raise "No last working state found - unable to restart if previous state is unknown" if last_working_state.blank?

        @case.state_machine.restart_the_clock!(
          acting_user: @user,
          acting_team: @user.case_team(@case),

          to_state: last_working_state,

          final_deadline: new_external_deadline,
          original_final_deadline: @case.external_deadline,

          message: message,
          details: {
            restart_the_clock_date: @restart_the_clock_date,
            new_status: last_working_state,
          },
        )

        @case.update!(current_state: last_working_state)
        @case.extend_deadline!(new_external_deadline, (@case.extended_times || 0))

        if flagged_aka_trigger?
          @case.update!(internal_deadline: new_internal_deadline)
        end

        @result = :ok
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
  def flagged_aka_trigger?
    @case.flagged? && @case.internal_deadline.present?
  end

  def paused_duration_days
    @paused_duration_days ||= (@case.stopped_at.to_date..@restart_the_clock_date).count
  end

  def new_external_deadline
    @new_external_deadline ||= begin
      @case.deadline_calculator.days_after(paused_duration_days, @case.external_deadline)
    end
  end

  def new_internal_deadline
    @new_internal_deadline ||= begin
      @case.deadline_calculator.days_after(paused_duration_days, @case.internal_deadline)
    end
  end

  def message
    internal_deadline_message =
      if flagged_aka_trigger?
        ["Old draft deadline: #{I18n.localize(@case.internal_deadline, format: :long)}."] +
        ["New draft deadline: #{I18n.localize(new_internal_deadline, format: :long)}."]
      else
        []
      end

    (
      ["Clock restarted from: #{I18n.localize(@restart_the_clock_date, format: :long)}."] +
      internal_deadline_message +
      ["Old final deadline: #{I18n.localize(@case.external_deadline, format: :long)}."] +
      ["New final deadline: #{I18n.localize(new_external_deadline, format: :long)}."]
    ).join("\n")
  end

  def validate_params
    if @restart_the_clock_date.blank?
      @case.errors.add(:restart_the_clock_date, "cannot be blank")
      @result = :validation_error
      return false
    end

    if @restart_the_clock_date > Date.today
      @case.errors.add(:restart_the_clock_date, "cannot be in the future")
      @result = :validation_error
      return false
    end

    if @restart_the_clock_date < @case.received_date.to_date
      @case.errors.add(:restart_the_clock_date, "cannot be before case was received")
      @result = :validation_error
      return false
    end

    if @restart_the_clock_date < @case.stopped_at.to_date
      @case.errors.add(:restart_the_clock_date, "cannot be before clock was stopped")
      @result = :validation_error
      return false
    end

    @result = :ok if @case.errors.empty?
  end
end
