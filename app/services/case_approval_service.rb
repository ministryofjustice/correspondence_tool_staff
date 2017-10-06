class CaseApprovalService

  attr_accessor :result, :error_message

  def initialize(user:, kase:, bypass_params:)
    @user = user
    @kase = kase
    @result = :incomplete
    @bypass_params = bypass_params
    @state_machine = CaseStateMachine.new(@kase,
                                          transition_class: CaseTransition,
                                          association_name: :transitions)
  end

  def call
    if @bypass_params.present?
      unless @bypass_params.valid?
        return
      end
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
        if @bypass_params.present? && @bypass_params.bypass_requested?
          bypass_press_and_private_approvals(assignment)
        else
          approve_and_progress_as_normal(assignment)
        end
        @result = :ok
      end
    rescue Statesman::GuardFailedError
      @result = :error
    end
  end

  def approve_and_progress_as_normal(assignment)
    @state_machine.approve!(@user, assignment)
  end

  def bypass_press_and_private_approvals(assignment)
    bypass_approval_for_team(BusinessUnit.press_office)
    bypass_approval_for_team(BusinessUnit.private_office)
    @state_machine.approve_and_bypass!(@user, assignment, @bypass_params.message)
  end

  def bypass_approval_for_team(team)
    assignment = @kase.approver_assignments.for_team(team).singular_or_nil
    assignment.bypassed! unless assignment.nil?
  end

end
