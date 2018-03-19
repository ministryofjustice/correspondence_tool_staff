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

end
