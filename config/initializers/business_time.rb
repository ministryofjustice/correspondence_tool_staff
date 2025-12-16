BusinessTime::Config.work_week = %w[mon tue wed thu fri]

ADDITIONAL_BANK_HOLIDAYS = (BankHoliday.get_bank_hols_scotland + BankHoliday.get_bank_hols_northern_ireland)
                             .reject { |holiday| BankHoliday.get_bank_hols_england_and_wales.any? { |ew| ew["date"] == holiday["date"] } }
                             .uniq { |holiday| holiday["date"] }
                             .freeze

BusinessTime::Config.holidays = BankHoliday.get_bank_hols_england_and_wales.map { |holiday| Date.parse(holiday["date"]) }
