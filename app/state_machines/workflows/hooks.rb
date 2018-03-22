class Workflows::Hooks

  def initialize(user:, kase:)
    @user = user
    @kase = kase
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
end
