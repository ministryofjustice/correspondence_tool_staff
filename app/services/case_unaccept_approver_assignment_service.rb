class CaseUnacceptApproverAssignmentService
  attr_accessor :result
  attr_accessor :error

  def initialize(assignment:)
    @assignment = assignment
    @user = @assignment.user
    @team = @assignment.team
    @result = :incomplete
    @dts = DefaultTeamService.new(assignment.case)
  end

  def call
    return false unless validate_accepted
    ActiveRecord::Base.transaction do
      if @team.press_office? || @team.private_office?
        kase = @assignment.case
        @dts.associated_teams(for_team: @team).each do |associated|
          if last_flagged_for_team(kase, @team, associated[:team])
            previous_assignment = kase.assignments
                                    .with_teams(associated[:team])
                                    .first
            unassign_approver_assignment previous_assignment
          end
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
    last_flag_unflag_transition = kase.transitions.where(
      event: ['flag_for_clearance', 'unflag_for_clearance']
    ).metadata_where(
      managing_team_id: by_team.id,
      approving_team_id: for_team.id,
    ).last
    last_flag_unflag_transition&.event == 'flag_for_clearance'
  end

  def unaccept_approver_assignment(assignment)
    assignment.case.state_machine.unaccept_approver_assignment!(@user, @team)
    assignment.user = nil
    assignment.pending!
    assignment.save!
  end

  def unassign_approver_assignment(assignment)
    kase = assignment.case
    kase.state_machine.unflag_for_clearance!(@user, @team, assignment.team)
    assignment.destroy
  end
end
