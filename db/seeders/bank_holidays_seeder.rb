module BankHolidays
  class Seeder
    def self.seed_from_file(path = "spec/fixtures/bank_holidays_response.json")
      file = File.read(path)
      data = JSON.parse(file)
      data.each_value do |_division, details|
        BankHolidays.create!(data: details)
      end
    end
  end
end
