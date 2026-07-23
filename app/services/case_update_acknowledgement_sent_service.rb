class CaseUpdateAcknowledgementSentService
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
      old_date = @case.acknowledgement_sent_at
      assign_component_params
      new_date = parse_date

      if new_date == :invalid
        @case.errors.add(:acknowledgement_sent_at, "is not a valid date")
        @result = :error
        raise ActiveRecord::Rollback
      end

      @case.acknowledgement_sent_at = new_date

      if @case.acknowledgement_sent_at != old_date
        @case.save!
        trigger_event(event_name(old_date), history_message(old_date))
        @result = :ok
      else
        @result = :no_changes
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    @result = :error
    @message = e.message
  rescue StandardError => e
    @message = e.message
    @result = :error
  end

private

  def assign_component_params
    @case.acknowledgement_sent_at_dd   = @params[:acknowledgement_sent_at_dd]
    @case.acknowledgement_sent_at_mm   = @params[:acknowledgement_sent_at_mm]
    @case.acknowledgement_sent_at_yyyy = @params[:acknowledgement_sent_at_yyyy]
  end

  def parse_date
    dd   = @params[:acknowledgement_sent_at_dd].to_s.strip
    mm   = @params[:acknowledgement_sent_at_mm].to_s.strip
    yyyy = @params[:acknowledgement_sent_at_yyyy].to_s.strip

    return nil if dd.blank? && mm.blank? && yyyy.blank?

    Date.new(yyyy.to_i, mm.to_i, dd.to_i)
  rescue ArgumentError
    :invalid
  end

  def event_name(old_date)
    old_date.present? ? "edit_case" : "record_acknowledgement_sent"
  end

  def history_message(old_date)
    return if old_date.blank?

    I18n.t(
      "event.acknowledgement_sent_date_updated",
      old_date: I18n.l(old_date),
      new_date: I18n.l(@case.acknowledgement_sent_at),
    )
  end

  def trigger_event(event, message = nil)
    @case.state_machine.send("#{event}!", acting_user: @user, acting_team: @case.managing_team, message:)
  end
end
