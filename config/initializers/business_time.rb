BusinessTime::Config.work_week = %w[mon tue wed thu fri]

Rails.application.config.after_initialize do
  unless Rails.env.test?
    holidays = BankHolidays.last

    # Load additional bank holidays for Scotland and Northern Ireland
    ADDITIONAL_BANK_HOLIDAYS = BankHolidays.last.dates_for_regions(:scotland, :northern_ireland)
    BusinessTime::Config.holidays = BankHolidays.last.dates_for(:england_and_wales).map(&:to_date)
  end
end
