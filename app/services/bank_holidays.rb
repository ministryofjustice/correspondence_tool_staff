class BankHolidays
  URL = "https://www.gov.uk/bank-holidays.json".freeze

  attr_reader :holidays

  def initialize(*)
    response = Net::HTTP.get(URI(URL))
    @holidays = JSON.parse(response)
  end

  def get_bank_holidays_for(division)
    @holidays[division]["events"]
  end

  def backup
    BankHolidsya.create
  end
end
