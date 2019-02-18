class Workflows::Hooks

  def initialize(user:, kase:, metadata:)
    @user = user
    @kase = kase
    @metadata = metadata
  end

  def notify_responder_message_received
    if @user != @kase.responder_assignment&.user
      NotifyResponderService.new(@kase, 'Message received').call
    end
  end

  def notify_responder_redraft_requested
    NotifyResponderService.new(@kase, 'Redraft requested').call
  end

  def notify_responder_ready_to_send
    NotifyResponderService.new(@kase, 'Ready to send').call if @kase.awaiting_dispatch?
  end

  def notify_managing_team_case_closed
    NotifyTeamService.new(@kase, 'Case closed').call
  end

  def reassign_user_email
    if @user !=  @metadata[:target_user]
        ActionNotificationsMailer
          .case_assigned_to_another_user(@kase, @metadata[:target_user])
          .deliver_later
    end
  end

  def assign_responder_email
    NotifyNewAssignmentService.new(team: @metadata[:target_team],
                                   assignment: @kase.responder_assignment
                                  ).run
  end

  def notify_approver_ready_for_review
    current_info = CurrentTeamAndUserService.new(@kase)

    assignment = @kase.approver_assignments
                     .for_team(current_info.team)
                     .first

    ActionNotificationsMailer.ready_for_press_or_private_review(assignment)
  end
end
