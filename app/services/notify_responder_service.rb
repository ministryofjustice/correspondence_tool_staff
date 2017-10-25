class NotifyResponderService
  attr_reader :result, :case
  def initialize(kase)
    @case = kase
    @result = :incomplete
  end

  def call
    if @case.approver_assignments.any?
      @result = :ok
      notify_responders
    else return @result
    end
  end

  private

  def notify_responders
    ActionNotificationsMailer
      .notify_information_office(@case)
      .deliver_later
  end
end
