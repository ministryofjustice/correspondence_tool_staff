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

        # Add to the history
        attrs = {
          case_id: @case.id,
          event: "restart_the_clock",
          to_state: last_good_state,
          to_workflow: @case.workflow,
          sort_key: CaseTransition.next_sort_key(@case),
          most_recent: false,
          acting_user: @user,
          acting_team: @user.case_team(@case),
        }
        CaseTransition.create!(attrs)

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

  def validate_params
    if @restart_the_clock_date.blank?
      @case.errors.add(:restart_the_clock_date, "cannot be blank")
      @result = :validation_error
    end

    if @restart_the_clock_date > Date.today
      @case.errors.add(:restart_the_clock_date, "cannot be in the future")
      @result = :validation_error
    end

    if @restart_the_clock_date < @case.stopped_at.to_date
      @case.errors.add(:restart_the_clock_date, "cannot be before clock was stopped")
      @result = :validation_error
    end

    if @restart_the_clock_date < @case.received_date.to_date
      @case.errors.add(:restart_the_clock_date, "cannot be before case was received")
      @result = :validation_error
    end

    @result = :ok if @case.errors.empty?
  end

  def last_good_state
    @case.transitions
      .where.not(event: %w[stopped restart_the_clock])
      .order(id: :desc)
      .first
      &.to_state
  end
end
