class CaseStopTheClockService
  attr_reader :result, :error

  def initialize(user, kase, stop_reason)
    @user = user
    @case = kase
    @stop_reason = stop_reason
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      if validate_params

        @case.state_machine.stop_the_clock!(
          acting_user: @user,
          acting_team: @user.case_team(@case),
          original_final_deadline: @case.external_deadline,
          message: @stop_reason,
        )

        #@case.stop_the_clock!(@extension_deadline)

        # # Add to case history
        # @case.update!(
        #   stop_at: Time.current,
        #   stop_reason: @stop_reason,
        #   stop_by: @user.id,
        # )

        # # Add to the history
        # attrs = {
        #   case_id: @case.id,
        #   event: "stop_the_clock",
        #   to_state: @case.current_state,
        #   to_workflow: @case.workflow,
        #   sort_key: CaseTransition.next_sort_key(@case),
        #   most_recent: false,
        #   acting_user: @user,
        #   acting_team: @user.case_team(@case),
        # }
        # CaseTransition.create!(attrs)

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
    if @stop_reason.blank?
      @case.errors.add(:stop_reason, "cannot be blank")
      @result = :validation_error
    end

    @result = :ok if @case.errors.empty?
  end
end
