class ReadyToSendNotificationService
  attr_reader :result, :case
  def initialize(kase)
    @case = kase
    @result = :incomplete
  end

  def call
    if @case.assignments.approver_assignments.any?
      @result = :ok
      notify_responders
    else return @result
    end
  end

  private

  def notify_responders
    ActionNotificationsMailer
      .case_ready_to_send(@case, responder.email)
      .deliver_later
  end
end
