class CaseUpdateSentToSsclService
  attr_accessor :result, :message

  def initialize(user:, kase:, params:)
    @case = kase
    @user = user
    @params = params
    @message = nil
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      @case.assign_attributes(@params)
      event = get_event

      if date_changed? || reason_added?
        @case.save!
        trigger_event(event, reason)
        @result = :ok
      else
        @result = :no_changes
      end
    end
  rescue => err
    @message = err.message
    @result = :error
  end

  private

  def reason
    if reason_added?
      "(Reason: #{@case.remove_sent_to_sscl_reason})"
    end
  end

  def get_event
    if reason_added?
      'date_sent_to_sscl_removed'
    else
      @case.sent_to_sscl_at_was.present? ? 'edit_case' : 'record_sent_to_sscl'
    end
  end

  def date_changed?
    @case.changed_attributes.keys.include?('sent_to_sscl_at')
  end

  def reason_added?
    @case.remove_sent_to_sscl_reason.present?
  end

  def trigger_event(event, message=nil)
    @case.state_machine.send("#{event}!", acting_user: @user, acting_team: @case.managing_team, message: message)
  end
end
