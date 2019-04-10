class CaseAssignResponderService
  attr_reader :result, :assignment

  def initialize(team:, kase:, role:, user:)
    @team = team
    @case = kase
    @role = role
    @user = user
    @result = :incomplete
  end

  def call
    Assignment.connection.transaction do
      @assignment = @case.assignments.new(team: @team, role: @role)
      if @assignment.valid?
        managing_team = @user.managing_teams.first
        @case.state_machine.assign_responder! acting_user: @user, acting_team: managing_team, target_team: @team
        @assignment.save
        @result = :ok
      else
        @result = :could_not_create_assignment
      end
    end
    @result == :ok
  end

end
