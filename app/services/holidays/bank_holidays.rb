module Holidays
  class BankHolidays
    URL = "https://www.gov.uk/bank-holidays.json".freeze

    def get_bank_hols(region)
      data = Rails.cache.fetch("bank_holidays_data", expires_in: 24.hours) do
        response = Net::HTTP.get(URI(URL))
        JSON.parse(response)
      end
      data[region]["events"]
    end

    def get_bank_hols_england_and_wales
      get_bank_hols("england-and-wales")
    end
    def get_bank_hols_scotland
      get_bank_hols("scotland")
    end
    def get_bank_hols_northern_ireland
      get_bank_hols("northern-ireland")
    end
  end
end
