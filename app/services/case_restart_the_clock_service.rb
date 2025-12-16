class CaseRestartTheClockService
  attr_reader :result, :error

  def initialize(user, kase, restart_the_clock_params)
    @user = user
    @case = CaseRestartTheClockDecorator.decorate kase
    @result = :incomplete

    @restart_at = begin
      Date.new(
        restart_the_clock_params[:restart_the_clock_date_yyyy].to_i,
        restart_the_clock_params[:restart_the_clock_date_mm].to_i,
        restart_the_clock_params[:restart_the_clock_date_dd].to_i,
      )
    rescue StandardError
      nil
    end
  end

  def call
    ActiveRecord::Base.transaction do
      if validate_params
        @case.state_machine.restart_the_clock!(
          acting_user: @user,
          acting_team: @user.case_team(@case),

          to_state: last_working_state,

          message: message,
          details: {
            restart_the_clock_date: @restart_at,
            new_status: last_working_state,
          },
        )

        update_attrs = {
          current_state: last_working_state,
          external_deadline: new_external_deadline,
        }
        update_attrs[:internal_deadline] = new_internal_deadline if flagged_aka_trigger?
        @case.update!(update_attrs)

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
    @paused_duration_days ||= (@case.stopped_at.to_date...@restart_at).count
  end

  def new_external_deadline
    @new_external_deadline ||= @case.deadline_calculator.closest_working_day_after(paused_duration_days, @case.external_deadline)
  end

  def new_internal_deadline
    @new_internal_deadline ||= @case.deadline_calculator.closest_working_day_after(paused_duration_days, @case.internal_deadline)
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
      ["Clock restarted from: #{I18n.localize(@restart_at, format: :long)}."] +
      internal_deadline_message +
      ["Old final deadline: #{I18n.localize(@case.external_deadline, format: :long)}."] +
      ["New final deadline: #{I18n.localize(new_external_deadline, format: :long)}."]
    ).join("\n")
  end

  def validate_params
    unless @case.stopped?
      @result = :error
      return false
    end

    if last_working_state.blank?
      @result = :last_working_state_missing
      return false
    end

    if @restart_at.blank?
      @case.errors.add(:restart_the_clock_date, :blank)
      @result = :validation_error
      return false
    end

    if @restart_at > Time.zone.today
      @case.errors.add(:restart_the_clock_date, :future)
      @result = :validation_error
      return false
    end

    if @restart_at < @case.received_date.to_date
      @case.errors.add(:restart_the_clock_date, :invalid)
      @result = :validation_error
      return false
    end

    if @restart_at < @case.stopped_at.to_date
      @case.errors.add(:restart_the_clock_date, :past)
      @result = :validation_error
      return false
    end

    @result = :ok if @case.errors.empty?
  end

  def last_working_state
    @last_working_state ||= @case.last_stop_the_clock_transition&.details&.fetch("last_status", nil)
  end
end
