class SystemLogEventPresenter
  attr_reader :event

  delegate :event_type, :timestamp, to: :event

  def initialize(event)
    @event = event
  end

  def name
    event_type.demodulize.underscore.humanize
  end

  def recipient
    return unless email_failed_event?

    data[:recipient]
  end

  def subject
    return unless email_failed_event?

    data[:subject]
  end

  def details
    return email_details if email_failed_event?
    return bank_holiday_ingest_failed_details if bank_holiday_ingest_failed_event?

    formatted_data
  end

  def email_failed_event?
    event_type.start_with?("Events::EmailFailed")
  end

  def rpi_failed_event?
    event_type.start_with?("Events::RpiUnprocessed")
  end

  def bank_holiday_ingest_failed_event?
    event_type.start_with?("Events::BankHolidayIngestFailed")
  end

private

  def data
    @data ||= event.data.with_indifferent_access
  end

  def email_details
    [
      data[:category]&.humanize,
      data[:email_type]&.humanize,
      formatted_status,
      data[:recipient_type]&.humanize,
      data[:case_number].presence && "Case #{data[:case_number]}",
      data[:notify_id].presence && "Notify #{data[:notify_id]}",
    ].compact.join(" | ")
  end

  def formatted_status
    return if data[:status].blank?

    data[:status].tr("-", "_").humanize
  end

  def formatted_data
    data.to_json
  end

  def bank_holiday_ingest_failed_details
    [
      data[:reason],
      data[:error_class].presence && data[:error_class].to_s,
      data[:failed_at].presence && "at #{data[:failed_at]}",
    ].compact.join(" | ")
  end
end
