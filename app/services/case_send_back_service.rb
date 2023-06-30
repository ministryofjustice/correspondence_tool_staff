class CaseSendBackService
  attr_accessor :result, :error_message

  def initialize(user:, kase:, comment:)
    @user = user
    @kase = kase
    @result = :incomplete
    @error_message = nil
    @comment = comment
  end

  def call
    process_send_back
    @result = :ok
  rescue ConfigurableStateMachine::InvalidEventError => e
    @error_message = "Error processing sending back: #{e.message}"
    Rails.logger.error(@error_message)
    @result = :error
  end

private

  def process_send_back
    ActiveRecord::Base.transaction do
      trigger_state_change
      reset_approval_flags
    end
  end

  def trigger_state_change
    if @comment.present?
      @kase.state_machine.add_message_to_case!(
        acting_user: @user,
        acting_team: @user.case_team(@kase),
        message: @comment,
        disable_hook: true,
      )
    end
    @kase.state_machine.send_back!(
      acting_user: @user,
      acting_team: @user.case_team(@kase),
    )
  end

  def reset_approval_flags
    # Reset all those approval flag from allt those approvers for this case
    @kase.approver_assignments.each do |assignment|
      assignment.update(approved: false)
    end
  end
end
