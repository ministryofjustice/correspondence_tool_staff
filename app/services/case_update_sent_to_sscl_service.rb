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
    event = get_event
    ActiveRecord::Base.transaction do
      @case.assign_attributes(@params)

      if has_changed?
        @case.save!
        trigger_event(event)
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

  def get_event
    @case.sent_to_sscl_at.present? ? 'edit_case' : 'record_sent_to_sscl'
  end

  def has_changed?
    @case.changed_attributes.keys.include?('sent_to_sscl_at')
  end

  def trigger_event(event)
    @case.state_machine.send("#{event}!", acting_user: @user, acting_team: @case.managing_team)
  end
end
