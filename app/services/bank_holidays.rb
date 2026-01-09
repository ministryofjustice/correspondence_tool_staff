class BankHolidays
  URL = "https://www.gov.uk/bank-holidays.json".freeze

  attr_reader :holidays

  def initialize(holidays_json = nil)
    # If no JSON is provided, fetch from the URL
    holidays_json ||= fetch_holidays.to_json

    @holidays = holidays_json.is_a?(String) ? JSON.parse(holidays_json) : holidays_json

  end

  def get_bank_holidays_for(division)
    @holidays.dig(division, "events") || []
  end

  def backup
    @holidays.each do |division, data|
      next unless data["events"]

      data["events"].each do |event|
        BankHolidays.find_or_initialize_by(
          division: division,
          date: event["date"],
        ).update!(title: event["title"])
      end
    end
  end

private

  def fetch_holidays
    response = Net::HTTP.get(URI(URL))
    JSON.parse(response)
  rescue StandardError
    {}
  end
end
