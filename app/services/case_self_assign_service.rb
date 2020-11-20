class CaseSelfAssignService
  attr_reader :result, :assignment

  def initialize(kase:, role:, user:)
    @case = kase
    @role = role
    @user = user
    @result = :incomplete
  end

  def call
    Assignment.connection.transaction do
      target_team = @user.responding_teams.first
      @assignment = @case.assignments.new(team: target_team, role: @role, user: @user)
      if @assignment.valid?
        managing_team = @user.responding_teams.first
        @case.state_machine.assign_responder! acting_user: @user, acting_team: managing_team, target_team: target_team
        @assignment.case.state_machine.accept_approver_assignment!(acting_user: @user, acting_team: target_team)
        @assignment.accepted!
        @assignment.save!
        @result = :ok
      else
        @result = :could_not_create_assignment
      end
    end
    @result == :ok
  end

end
