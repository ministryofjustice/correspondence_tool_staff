class BankHolidaysService
  URL = "https://www.gov.uk/bank-holidays.json".freeze

  attr_reader :holidays

  def initialize(force: false)
    SentryContextProvider.set_context

    @force = force
    @holidays = {}
    @ingest_errored = false

    ingest
    backup
  end

  # Persist the latest snapshot of holidays if it has changed.
  # Pass force: true to write a new record even when the data is unchanged.
  def backup
    return unless holidays.is_a?(Hash)

    if holidays.empty?
      publish_ingest_failed_event(reason: "ingest returned empty data") unless @ingest_errored
      return
    end

    hash_value = Digest::MD5.hexdigest(JSON.generate(holidays))

    if !@force && (BankHoliday.last&.hash_value == hash_value)
      return
    end

    ::BankHoliday.create!(data: holidays, hash_value: hash_value)
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def ingest
    uri = URI(URL)
    response_body = Net::HTTP.get(uri)

    @holidays = JSON.parse(response_body)
  rescue StandardError => e
    @ingest_errored = true
    Sentry.capture_message "BankHolidaysService ingest failure --- Error: #{e.message}"
    Sentry.capture_exception(e)
    publish_ingest_failed_event(reason: e.message, error_class: e.class.name)
  ensure
    @holidays ||= {}
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

private

  def publish_ingest_failed_event(reason:, error_class: nil)
    Rails.configuration.event_store.publish(
      Events::BankHolidayIngestFailed.build(
        reason: reason,
        error_class: error_class,
        failed_at: Time.current.iso8601,
      ),
    )
  end
end
