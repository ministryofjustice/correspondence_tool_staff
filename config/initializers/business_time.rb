BusinessTime::Config.work_week = %w[mon tue wed thu fri]

Rails.application.config.to_prepare do
  next unless defined?(BankHolidays)

  # During setup/migrations the table may not exist yet.
  if ActiveRecord::Base.connection.data_source_exists?("bank_holidays")
    last = BankHolidays.last
    if last.present?
      hols = last.dates_for(:england_and_wales).map(&:to_date)
      BusinessTime::Config.holidays = hols
    end
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
  # Database or table not ready yet (e.g. during db:setup/migrate).
  # Safely skip configuring holidays; it will be set on next boot.
end
