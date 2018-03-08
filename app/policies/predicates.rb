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
    NotifyResponderService.new(@kase, 'Message received').call if able_to_send?(@user, @kase)
  end

  def user_is_assigned_disclosure_specialist?
    @kase.assignments.with_teams(BusinessUnit.dacu_disclosure).for_user(@user).present?
  end

  private

  def able_to_send?(user, kase)
    message_not_sent_by_responder?(user, kase) && case_has_responder(kase)
  end

  def message_not_sent_by_responder?(user, kase)
    user != kase.responder_assignment&.user
  end

  def case_has_responder(kase)
    kase.responder_assignment&.user.present?
  end
end



