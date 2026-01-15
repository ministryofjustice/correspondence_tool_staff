BusinessTime::Config.work_week = %w[mon tue wed thu fri]

Rails.application.config.to_prepare do
  if defined?(BankHolidays)
    hols = BankHolidays.last.dates_for(:england_and_wales).map(&:to_date)
    BusinessTime::Config.holidays = hols
  end
end
