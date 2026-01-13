class BankHolidaysService
  URL = "https://www.gov.uk/bank-holidays.json".freeze

  attr_accessor :holidays

  def initialize
    @holidays = fetch_holidays
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
