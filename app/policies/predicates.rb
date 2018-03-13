class Predicates
  def initialize(user:, kase:)
    @user = user
    @kase = kase
  end

  def responder_is_member_of_assigned_team?
    if @kase.responding_team
      @kase.responding_team.users.include?(@user)
    else
      false
    end
  end

  def user_is_assigned_disclosure_specialist?
    @kase.assignments.with_teams(BusinessUnit.dacu_disclosure).for_user(@user).present?
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
    NotifyResponderService.new(@kase, 'Ready to send').call
  end
end
