# config/business_time.rb
module BusinessTimeBootstrap
  module_function

  def configure!
    # 1) Load latest record
    record = BankHolidays.order(created_at: :desc).first

    # 2) If missing, try again
    unless record
      BankHolidaysService.new
      record = BankHolidays.order(created_at: :desc).first
    end

    # 3) Fail if still missing
    raise "Bank holidays data is required but not available" unless record

    # 4) Config
    BusinessTime::Config.work_week = %w[mon tue wed thu fri]
    BusinessTime::Config.holidays  = record.dates_for(:england_and_wales).map(&:to_date)

    # rubocop:disable Lint/Syntax
    ADDITIONAL_BANK_HOLIDAYS = record.dates_for_regions(:scotland, :northern_ireland).map(&:to_date)
    # rubocop:enable Lint/Syntax
  end
end
