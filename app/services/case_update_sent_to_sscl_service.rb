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
      already_sent_to_sscl = @case.sent_to_sscl_at.present?
      @case.assign_attributes(@params)

      if has_changed?
        @case.save!
        trigger_event unless already_sent_to_sscl
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

  def has_changed?
    @case.changed_attributes.keys.include?('sent_to_sscl_at')
  end

  def trigger_event
    @case.state_machine.record_sent_to_sscl!(acting_user: @user, acting_team: @case.managing_team)
  end
end
