class NotifyResponderService
  attr_reader :result, :case
  def initialize(kase)
    @case = kase
    @result = :incomplete
  end

  def call
    @result = :ok
    notify_responders
  end

  private

  def notify_responders
    ActionNotificationsMailer
      .notify_information_officers(@case)
      .deliver_later
  end
end
