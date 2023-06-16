class CaseApprovalService
  attr_accessor :result

  def initialize(user:, kase:, bypass_params:)
    @user = user
    @kase = kase
    @result = :incomplete
    @bypass_params = bypass_params
  end

  def call
    if @bypass_params.present? && !@bypass_params.valid?
      return
    end

    process_approval
  end

  def error_message
    @bypass_params.error_message
  end

private

  def process_approval
    begin
      ActiveRecord::Base.transaction do
        assignment = @kase.approver_assignments
                       .with_teams(@user.approving_team)
                       .singular
        assignment.update!(approved: true)
        @kase.log_compliance_date!

        if @bypass_params.present? && @bypass_params.bypass_requested?
          bypass_press_and_private_approvals(assignment)
        else
          approve_and_progress_as_normal(assignment)
        end
        @result = :ok
      end
    rescue ConfigurableStateMachine::InvalidEventError
      @result = :error
    end
    notify_next_approver if @result == :ok
    result
  end

  def approve_and_progress_as_normal(assignment)
    @kase.state_machine.approve!(acting_user: @user, acting_team: assignment.team)
  end

  def bypass_press_and_private_approvals(assignment)
    bypass_approval_for_team(BusinessUnit.press_office)
    bypass_approval_for_team(BusinessUnit.private_office)
    @kase.state_machine.approve_and_bypass!(acting_user: @user, acting_team: assignment.team, message: @bypass_params.message)
  end

  def bypass_approval_for_team(team)
    assignment = @kase.approver_assignments.for_team(team).singular_or_nil
    assignment.bypassed! unless assignment.nil?
  end

  def notify_next_approver
    if @kase.current_state
           .in?(%w[pending_press_office_clearance pending_private_office_clearance])

      current_info = CurrentTeamAndUserService.new(@kase)
      assignment = @kase.approver_assignments
                       .for_team(current_info.team)
                       .first

      ActionNotificationsMailer
          .ready_for_press_or_private_review(assignment)
          .deliver_later
    end
  end
end
