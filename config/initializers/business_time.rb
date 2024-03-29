BusinessTime::Config.work_week = %w[mon tue wed thu fri]

ADDITIONAL_BANK_HOLIDAYS = [
  "2023-07-12", # Battle of the Boyne
  "2023-08-07", # Summer bank holiday
  "2023-11-30", # St Andrew's Day
  "2024-01-02", # 2nd January
  "2024-03-18", # St Patrick's Day
  "2024-07-12", # Battle of the Boyne
  "2024-08-05", # Summer bank holiday
  "2024-12-02", # St Andrew's Day (substitute day)
  "2025-01-02", # 2nd January
  "2025-03-17", # St Patricks's Day
  "2025-07-14", # Battle of the Boyne (substitute day)
  "2025-08-04", # Summer bank holiday
  "2025-12-01", # St Andrew's Day (substitute day)
].freeze

ew_bank_holidays = %w[
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
  2019-01-01
  2019-04-19
  2019-04-22
  2019-05-06
  2019-05-27
  2019-08-26
  2019-12-25
  2019-12-26
  2020-01-01
  2020-04-10
  2020-04-13
  2020-05-08
  2020-05-25
  2020-08-31
  2020-12-25
  2020-12-28
  2021-01-01
  2021-04-02
  2021-04-05
  2021-05-03
  2021-05-31
  2021-08-30
  2021-12-27
  2021-12-28
  2022-01-03
  2022-04-15
  2022-04-18
  2022-05-02
  2022-06-02
  2022-06-03
  2022-08-29
  2022-09-19
  2022-12-26
  2022-12-27
  2023-01-02
  2023-04-07
  2023-04-10
  2023-05-01
  2023-05-08
  2023-05-29
  2023-08-28
  2023-12-25
  2023-12-26
  2024-01-01
  2024-03-29
  2024-04-01
  2024-05-06
  2024-05-27
  2024-08-26
  2024-12-25
  2024-12-26
  2025-01-01
  2025-04-18
  2025-04-21
  2025-05-05
  2025-05-26
  2025-08-25
  2025-12-25
  2025-12-26
]

hols = if Rails.env.production?
         BankHoliday.all.map(&:date)
       else
         ew_bank_holidays
       end

BusinessTime::Config.holidays = hols.map(&:to_date)
