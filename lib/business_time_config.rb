module BusinessTimeConfig
module_function

  # reader to assign at runtime
  def additional_bank_holidays
    @additional_bank_holidays || []
  end

  def configure!
    begin
      ActiveRecord::Base.connection.table_exists?("bank_holidays")
    rescue StandardError
      Rails.logger.error "Bank holidays table is not available. BusinessTimeConfig cannot be configured."
      return
    end

    # 1) Load latest record
    record = BankHoliday.order(created_at: :desc).first

    # 2) If missing, try again
    unless record
      BankHolidaysService.new
      record = BankHoliday.order(created_at: :desc).first
    end

    # 3) Fail if still missing
    raise "Bank holidays data is required but not available" unless record

    # 4) Config
    BusinessTime::Config.work_week = %w[mon tue wed thu fri]
    BusinessTime::Config.holidays = record.dates_for(:england_and_wales).map(&:to_date)
    @additional_bank_holidays = record.dates_for_regions(:scotland, :northern_ireland).freeze
  end
end
