#BusinessTime::Config.load("#{Rails.root}/config/business_time.yml")

# or you can configure it manually:  look at me!  I'm Tim Ferriss!
BusinessTime::Config.work_week = %w( mon tue wed thu fri )
BusinessTime::Config.holidays = BankHoliday.all.map(&:date).map(&:to_date)
