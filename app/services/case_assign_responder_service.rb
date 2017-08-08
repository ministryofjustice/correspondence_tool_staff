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
        managing_team = @user.managing_team_roles.first.team
        @case.state_machine.assign_responder! @user, managing_team, @team
        @assignment.save
        if @team.email.blank?
          @team.responders.each do |responder|
            AssignmentMailer
              .new_assignment(@assignment, responder.email)
              .deliver_later
          end
        else
          AssignmentMailer.new_assignment(@assignment, @team.email).deliver_later
        end
        @result = :ok
        true
      else
        @result = :could_not_create_assignment
        false
      end
    end
  end
end
