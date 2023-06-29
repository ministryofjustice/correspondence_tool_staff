class UserReassignmentService
  attr_reader :result, :error

  def initialize(assignment:,
                 target_user:, acting_user:,
                 target_team: nil, acting_team: nil)

    @assignment             = assignment
    @original_assigned_user = assignment.user_id
    @kase                   = assignment.case
    @target_user            = target_user
    @acting_user            = acting_user
    @target_team            = target_team || get_team_for_user_and_case_with_role(@assignment.team.role, @target_user)
    @acting_team            = acting_team || get_user_team(@acting_user)
    @result = :incomplete
  end

  def call
    if @target_user.id == @assignment.user_id
      @result = :no_changes
    else
      ActiveRecord::Base.transaction do
        # Add an entry in transitions table
        @kase.state_machine.reassign_user!(target_user: @target_user,
                                           target_team: @target_team,
                                           acting_user: @acting_user,
                                           acting_team: @acting_team)

        # Update the assignment
        @assignment.update!(user_id: @target_user.id)

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

  def get_team_for_user_and_case_with_role(role, user)
    teams = @kase.teams.where(role:) & user.teams.where(role:)
    raise "Unable to allocate acting team with role #{role} to user #{user.id}" if teams.empty?

    teams.first
  end

  def get_user_team(user)
    team = nil
    get_roles_for_case.each do |role|
      team = @assignment.case.team_for_unassigned_user(user, role) if team.nil?
    end
    team
  end

  def get_roles_for_case
    roles = Set.new
    @kase.assignments.each do |assignment|
      roles << assignment.role.sub("ing", "er").to_sym
    end
    roles.delete(:manager)
  end
end
