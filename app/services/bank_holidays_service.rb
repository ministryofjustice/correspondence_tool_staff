class BankHolidaysService
  URL = "https://www.gov.uk/bank-holidays.json".freeze

  attr_reader :holidays

  def initialize(force: false)
    SentryContextProvider.set_context

    @force = force
    @holidays = {}

    ingest
    backup
  end

  # Persist the latest snapshot of holidays if it has changed.
  # Pass force: true to write a new record even when the data is unchanged.
  def backup
    return unless holidays.is_a?(Hash)
    return if holidays.empty?

    hash_value = Digest::MD5.hexdigest(JSON.generate(holidays))

    unless @force
      record = BankHoliday.last
      return if record&.hash_value == hash_value
    end

    ::BankHoliday.create!(data: holidays, hash_value: hash_value)
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def ingest
    uri = URI(URL)
    response_body = Net::HTTP.get(uri)

    @holidays = JSON.parse(response_body)
  rescue StandardError => e
    Sentry.capture_message "BankHolidaysService ingest failure --- Error: #{e.message}"
    Sentry.capture_exception(e)
  ensure
    @holidays ||= {}
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName
end
