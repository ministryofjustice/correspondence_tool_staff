require 'net/http'
require 'json'

class BankHolidayImporter
  GOV_UK_URL = 'https://www.gov.uk/bank-holidays.json'

  def self.import!
    response = Net::HTTP.get(URI(GOV_UK_URL))
    holidays = JSON.parse(response)

    holidays.each do |division, data|
      data["events"].each do |event|
        BankHoliday.find_or_create_by(
          date: event["date"],
          name: event["title"],
          division: division,
          notes: event["notes"],
          bunting: event["bunting"]
        )
      end
    end
  end
end
