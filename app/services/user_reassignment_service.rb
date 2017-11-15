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
    @target_team            = target_team || @assignment.case
                                                 .team_for_user(@target_user)
    @acting_team            = acting_team || @assignment.case
                                                 .team_for_user(@acting_user)
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
