class BankHolidaysService
  URL = "https://www.gov.uk/bank-holidays.json".freeze

  attr_reader :holidays

  def initialize
    SentryContextProvider.set_context

    @holidays = {}

    ingest
    backup
  end

  # Persist the latest snapshot of holidays if it has changed
  def backup
    return unless holidays.is_a?(Hash)
    return if holidays.empty?

    hash_value = Digest::MD5.hexdigest(JSON.generate(holidays))

    # Avoid writing duplicate records when the data hasn't changed
    record = BankHoliday.last
    return if record&.hash_value == hash_value

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
