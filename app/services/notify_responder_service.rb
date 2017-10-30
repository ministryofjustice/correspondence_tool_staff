class NotifyResponderService
  attr_reader :result, :case
  def initialize(kase)
    @case = kase
    @result = :incomplete
  end

  def call
    notify_responders
    @result = :ok
  end

private

  def notify_responders
    ActionNotificationsMailer
      .notify_information_officers(@case)
      .deliver_later
  end
end
