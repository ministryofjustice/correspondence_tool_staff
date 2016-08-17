#BusinessTime::Config.load("#{Rails.root}/config/business_time.yml")

# or you can configure it manually:  look at me!  I'm Tim Ferriss!
BusinessTime::Config.beginning_of_workday = "09:00 am"
BusinessTime::Config.end_of_workday = "17:00 pm"
BusinessTime::Config.work_week = %w( mon tue wed thu fri )
BusinessTime::Config.holidays = BankHoliday.all.map(&:date).map(&:to_date)
