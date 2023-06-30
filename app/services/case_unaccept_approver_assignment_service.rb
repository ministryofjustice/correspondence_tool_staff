class CaseUnacceptApproverAssignmentService
  attr_accessor :result, :error

  def initialize(assignment:)
    @assignment = assignment
    @user = @assignment.user
    @team = @assignment.team
    @result = :incomplete
    @kase = assignment.case
    @dts = DefaultTeamService.new(assignment.case)
  end

  def call
    return false unless validate_accepted

    ActiveRecord::Base.transaction do
      if @team.press_office? || @team.private_office?
        @dts.associated_teams(for_team: @team).each do |associated|
          next unless last_flagged_for_team(@kase, @team, associated[:team])

          previous_assignment = @kase.assignments
                                  .with_teams(associated[:team])
                                  .first
          unassign_approver_assignment previous_assignment
        end
        unassign_approver_assignment @assignment
      else
        unaccept_approver_assignment @assignment
      end
      @result = :ok
      true
    end
  end

private

  def validate_accepted
    if @assignment.accepted?
      true
    else
      @result = :not_accepted
      false
    end
  end

  def last_flagged_for_team(kase, by_team, for_team)
    flagging_events = %w[take_on_for_approval flag_for_clearance unflag_for_clearance]
    flagging_transitions = kase.transitions.where(event: flagging_events)
    flagging_transitions_for_teams = flagging_transitions.where(acting_team_id: by_team.id, target_team_id: for_team.id)
    last_flagging_transition_for_team = flagging_transitions_for_teams.last
    last_flagging_transition_for_team&.event.in? %w[take_on_for_approval flag_for_clearance]
  end

  def unaccept_approver_assignment(assignment)
    assignment.case.state_machine.unaccept_approver_assignment!(acting_user: @user, acting_team: @team)
    assignment.user = nil
    assignment.pending!
    assignment.save!
  end

  def unassign_approver_assignment(assignment)
    @kase.state_machine.unflag_for_clearance!(acting_user: @user, acting_team: @team, target_team: assignment.team)
    assignment.destroy # rubocop:disable Rails/SaveBang
  end
end
