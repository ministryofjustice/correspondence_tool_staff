#BusinessTime::Config.load("#{Rails.root}/config/business_time.yml")

# or you can configure it manually:  look at me!  I'm Tim Ferriss!
BusinessTime::Config.work_week = %w( mon tue wed thu fri )

hols = nil
unless Rails.env.production?
  hols = %w(
      2016-01-01
      2016-03-25
      2016-03-28
      2016-05-02
      2016-05-30
      2016-08-29
      2016-12-26
      2016-12-27
      2017-01-02
      2017-04-14
      2017-04-17
      2017-05-01
      2017-05-29
      2017-08-28
      2017-12-25
      2017-12-26
      2018-01-01
      2018-03-30
      2018-04-02
      2018-05-07
      2018-05-28
      2018-08-27
      2018-12-25
      2018-12-26
  )
else
  hols = BankHoliday.all.map(&:date)
end
BusinessTime::Config.holidays = hols.map(&:to_date)
