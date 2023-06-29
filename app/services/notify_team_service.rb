class NotifyTeamService
  attr_reader :result, :case

  def initialize(kase, mail_type)
    @case = kase
    @result = :incomplete
    @mail_type = mail_type
  end

  def call
    notify_managing_team
    @result = :ok
  end

private

  def notify_managing_team
    ActionNotificationsMailer
      .notify_team(@case.managing_team, @case, @mail_type)
      .deliver_later
  end
end
