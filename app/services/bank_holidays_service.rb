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

  def get_bank_holidays_for(division)
    holidays.dig(division, "events") || []
  end

  # Persist the latest snapshot of holidays if it has changed
  def backup
    return unless holidays.present?

    hash_value = Digest::MD5.hexdigest(holidays.to_json)
    last_record = BankHolidays.last

    # Avoid writing duplicate records when the data hasn't changed
    Rails.logger.error(last_record.dates_for(:england_and_wales))

    return if last_record&.hash_value == hash_value

    ::BankHolidays.create!(data: holidays, hash_value: hash_value)
  end

  private

  # Load holidays from cache or remote, returning a parsed JSON hash
  def load_holidays
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      raw_json = fetch_holidays
      return {} if raw_json.blank?

      JSON.parse(raw_json)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse bank holidays JSON: #{e.message}")
      {}
    end
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
