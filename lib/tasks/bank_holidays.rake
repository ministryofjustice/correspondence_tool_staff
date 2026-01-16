namespace :bank_holidays do
  desc "Run the BankHolidayService"
  task run: :environment do
    BankHolidaysService.new
  end
end
