BusinessTime::Config.work_week = %w[mon tue wed thu fri]

Rails.application.reloader.to_prepare do
  record = BankHolidays.order(created_at: :desc).first
  unless record
    BankHolidaysService.new
    record = BankHolidays.order(created_at: :desc).first
  end
  raise "Bank holidays data is required but not available" unless record

  Object.send(:remove_const, :ADDITIONAL_BANK_HOLIDAYS) if Object.const_defined?(:ADDITIONAL_BANK_HOLIDAYS)
  # rubocop:disable Lint/ConstantDefinitionInBlock
  ADDITIONAL_BANK_HOLIDAYS = record.dates_for_regions(:scotland, :northern_ireland).map(&:to_date)
  # rubocop:enable Lint/ConstantDefinitionInBlock
  BusinessTime::Config.holidays = record.dates_for(:england_and_wales).map(&:to_date)
end
