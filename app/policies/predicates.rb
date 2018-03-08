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

  def notify_responder_message_received
    if @user != @kase.responder_assignment&.user
      NotifyResponderService.new(@kase, 'Message received').call
    end
  end
  
  def user_is_assigned_disclosure_specialist?
    @kase.assignments.with_teams(BusinessUnit.dacu_disclosure).for_user(@user).present?
  end
end
