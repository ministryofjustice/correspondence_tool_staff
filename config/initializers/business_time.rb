BusinessTime::Config.work_week = %w[mon tue wed thu fri]

Rails.application.config.after_initialize do
  if Rails.env.test?
    if BankHolidays.count == 0
      # In tests, use a fixed set of bank holidays from fixtures
      fixture_json = File.read(Rails.root.join("spec/fixtures/bank_holidays_response.json"))
      parsed_fixture = JSON.parse(fixture_json)
      BankHolidays.create!(data: parsed_fixture, hash_value: "test-fixture")
    end
  end

  holidays = BankHolidays.last

  # Load additional bank holidays for Scotland and Northern Ireland
  ADDITIONAL_BANK_HOLIDAYS = BankHolidays.last.dates_for_regions(:scotland, :northern_ireland)
  BusinessTime::Config.holidays = BankHolidays.last.dates_for(:england_and_wales).map(&:to_date)
end
