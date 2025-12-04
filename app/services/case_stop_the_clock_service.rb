class CaseStopTheClockService
  attr_reader :result, :error

  def initialize(user, kase, stop_the_clock_params)
    @user = user
    @case = CaseStopTheClockDecorator.decorate kase

    @stop_categories = stop_the_clock_params[:stop_the_clock_categories]&.reject(&:blank?)&.uniq || []
    @stop_reason = stop_the_clock_params[:stop_the_clock_reason]

    @stop_at = begin
      Date.new(
        stop_the_clock_params[:stop_the_clock_date_yyyy].to_i,
        stop_the_clock_params[:stop_the_clock_date_mm].to_i,
        stop_the_clock_params[:stop_the_clock_date_dd].to_i,
      )
    rescue StandardError
      nil
    end

    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      if validate_params
        @case.state_machine.stop_the_clock!(
          acting_user: @user,
          acting_team: @user.case_team(@case),

          message: message,
          details: {
            stop_the_clock_categories: @stop_categories,
            stop_the_clock_reason: @stop_reason,
            stop_the_clock_date: @stop_at,
            last_status: @case.current_state,
          },
        )

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

  def message
    (
      ["Clock stopped on: #{I18n.localize(@stop_at, format: :long)}.\n"] +
      @stop_categories.map { |reason| "Reason: #{reason}.\n" } +
      ["\nDescription: #{@stop_reason}"]
    ).join
  end

  def validate_params
    if @stop_categories.empty?
      @case.errors.add(:stop_the_clock_categories, :blank)
      @result = :validation_error
    end

    if @stop_reason.blank?
      @case.errors.add(:stop_the_clock_reason, :blank)
      @result = :validation_error
    end

    if @stop_at.blank?
      @case.errors.add(:stop_the_clock_date, :blank)
      @result = :validation_error
      return false
    end

    if @stop_at < @case.received_date
      @case.errors.add(:stop_the_clock_date, :invalid)
      @result = :validation_error
      return false
    end

    if @stop_at > Time.zone.today
      @case.errors.add(:stop_the_clock_date, :future)
      @result = :validation_error
      return false
    end

    if @case.restarted_at && (@stop_at < @case.restarted_at)
      @case.errors.add(:stop_the_clock_date, :past)
      @result = :validation_error
      return false
    end

    @result = :ok if @case.errors.empty?
  end
end
