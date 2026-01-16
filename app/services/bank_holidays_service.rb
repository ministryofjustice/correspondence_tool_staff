require Rails.root.join('app/models/bank_holidays')

class BankHolidaysService
  URL = "https://www.gov.uk/bank-holidays.json".freeze
  CACHE_KEY = "bank_holidays_service:data".freeze
  CACHE_TTL = 12.hours

  attr_reader :holidays

  def initialize
    @holidays = load_holidays
    backup
  end

  # Persist the latest snapshot of holidays if it has changed
  def backup
    return unless holidays.present?
    return unless holidays.is_a?(Hash)
    return if holidays.empty?

    hash_value = Digest::MD5.hexdigest(JSON.generate(holidays))

    # Avoid writing duplicate records when the data hasn't changed
    record = BankHolidays.last
    return if record&.hash_value == hash_value

    ::BankHolidays.create!(data: holidays, hash_value: hash_value)
  end

  private

  # Load holidays from the remote endpoint, returning a parsed JSON hash.
  # On any error (network failure, blank body, invalid JSON), returns {}
  # and deliberately does NOT fall back to any previously cached value.
  # When a valid payload is retrieved, it is written to cache for other
  # parts of the app to reuse.
  def load_holidays
    raw_json = fetch_holidays
    return {} if raw_json.blank?

    parsed = JSON.parse(raw_json)
    unless parsed.is_a?(Hash)
      Rails.logger.error("Parsed bank holidays JSON is not a Hash")
      return {}
    end

    # Cache only successful, valid payloads
    Rails.cache.write(CACHE_KEY, parsed, expires_in: CACHE_TTL)
    parsed
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse bank holidays JSON: #{e.message}")
    {}
  rescue StandardError => e
    # Any unexpected issue should be treated as no data
    Rails.logger.error("Unexpected error while loading bank holidays: #{e.message}")
    {}
  end

  # Fetch holidays from the remote endpoint and return the raw body as a String
  def fetch_holidays
    uri = URI(URL)
    response_body = Net::HTTP.get(uri)
    Rails.logger.info("Fetched bank holidays data: #{response_body.bytesize} bytes")
    response_body
  rescue StandardError => e
    Rails.logger.error("Failed to fetch bank holidays: #{e.message}")
    ""
  end
end
