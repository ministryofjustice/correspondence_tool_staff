class UserReassignmentService
  attr_reader :result, :error

  def initialize(assignment:,
                 target_user:, acting_user:,
                 target_team: nil, acting_team: nil)

    puts ">>>>>>>>>>>> target_user #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
    ap target_user
    puts ">>>>>>>>>>>> target_team #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
    ap target_team
    puts ">>>>>>>>>>>> acting_user #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
    ap acting_user
    puts ">>>>>>>>>>>> acting_team #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
    ap acting_team
    puts ">>>>>>>>>>>> assignment #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
    ap assignment
    puts ">>>>>>>>>>>> assignment teams #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
    ap assignment.team


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
    ActiveRecord::Base.transaction do
      #Add an entry in transitions table
      @kase.state_machine.reassign_user!(target_user: @target_user,
                                         target_team: @target_team,
                                         acting_user: @acting_user,
                                         acting_team: @acting_team)

      #Update the assignment
      @assignment.update(user_id: @target_user.id)

      @result = :ok
    end

    # If everything is good email the user
    notify_target_user

    @result
  rescue => err
    Rails.logger.error err.to_s
    Rails.logger.error err.backtrace.join("\n\t")
    @error = err
    @result = :error
  end

  private

  def get_team_for_user_and_case_with_role(role, user)
    teams = @kase.teams.where(role: role) & user.teams.where(role: role)
    raise "Unable to allocate acting team with role #{role} to user #{user.id}" if teams.empty?
    teams.first
  end

  def get_user_team(user)
    @assignment.case.team_for_user(user, :responder) ||  @assignment.case.team_for_user(user, :manager)

  end

  def notify_target_user

    # User is not assigning to themselves and
    # the assigned user changed

    if @acting_user != @target_user &&
        @original_assigned_user != @assignment.user_id

        ActionNotificationsMailer
          .case_assigned_to_another_user(@kase, @target_user)
          .deliver_later
    end
  end
end
