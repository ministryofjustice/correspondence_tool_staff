class NotifyResponderService
  attr_reader :result, :case

  def initialize(kase, mail_type)
    @case = kase
    @result = :incomplete
    @mail_type = mail_type
  end

  def call
    notify_responders
    @result = :ok
  end

private

  def notify_responders
    ActionNotificationsMailer
      .notify_information_officers(@case, @mail_type)
      .deliver_later
  end
end
