BusinessTime::Config.work_week = %w[mon tue wed thu fri]

bank_holidays = BankHolidays.last

ADDITIONAL_BANK_HOLIDAYS = bank_holidays.dates_for_regions(:northern_ireland, :scotland).map(&:to_date).freeze

hols = BankHolidays.last.date_for(:england_and_wales).freeze

BusinessTime::Config.holidays = hols.map(&:to_date)
