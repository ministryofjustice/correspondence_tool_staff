BusinessTime::Config.work_week = %w[mon tue wed thu fri]

Rails.application.config.after_initialize do
  if Rails.env.test? && BankHolidays.count.zero?
    BankHolidaysService.new
  end

  # Load additional bank holidays for Scotland and Northern Ireland and ensure global scope
  # rubocop:disable Lint/ConstantDefinitionInBlock
  ADDITIONAL_BANK_HOLIDAYS = BankHolidays.last.dates_for_regions(:scotland, :northern_ireland)
  # rubocop:enable Lint/ConstantDefinitionInBlock
  BusinessTime::Config.holidays = BankHolidays.last.dates_for(:england_and_wales).map(&:to_date)
end
