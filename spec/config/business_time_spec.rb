require "rails_helper"

RSpec.describe "BusinessTimeConfig.configure!" do
  before do
    # Define a minimal stub for BusinessTime::Config if the gem isn't loaded in test
    unless defined?(BusinessTime::Config)
      stub_const("BusinessTime", Module.new)

      config_mod = Module.new
      config_mod.singleton_class.class_eval do
        attr_accessor :work_week, :holidays
      end
      stub_const("BusinessTime::Config", config_mod)
    end

    # Ensure clean state before each example
    BusinessTime::Config.work_week = nil
    BusinessTime::Config.holidays = nil
    BusinessTimeConfig.instance_variable_set(:@additional_bank_holidays, nil)
  end

  # strings as stored in DB
  def build_record(ew_dates: %w[2026-12-25], extra_dates: %w[2026-01-01 2026-03-17])
    instance_double(
      BankHolidays,
      dates_for: ew_dates,
      dates_for_regions: extra_dates,
    )
  end

  it "sets work_week and holidays, and stores additional_bank_holidays when a record exists" do
    record = build_record(ew_dates: %w[2026-12-25 2026-12-28], extra_dates: %w[2026-01-01])

    relation = instance_double(ActiveRecord::Relation, first: record)
    allow(BankHolidays).to receive(:order).with(created_at: :desc).and_return(relation)

    # BankHolidaysService should not be called because record exists
    expect(BankHolidaysService).not_to receive(:new)

    require Rails.root.join("config/business_time")
    BusinessTimeConfig.configure!

    expect(BusinessTime::Config.work_week).to eq(%w[mon tue wed thu fri])

    # holidays are mapped to Date objects
    expect(BusinessTime::Config.holidays).to all(be_a(Date))
    expect(BusinessTime::Config.holidays).to contain_exactly(Date.parse("2026-12-25"), Date.parse("2026-12-28"))
    # additional holidays are not
    expect(BusinessTimeConfig.additional_bank_holidays).to eq(%w[2026-01-01])
    expect(BusinessTimeConfig.additional_bank_holidays).to be_frozen
  end

  it "invokes BankHolidaysService and retries when no record is initially available" do
    record = build_record(ew_dates: %w[2026-05-04], extra_dates: %w[2026-01-01 2026-11-30])

    relation_nil = instance_double(ActiveRecord::Relation, first: nil)
    relation_rec = instance_double(ActiveRecord::Relation, first: record)

    expect(BankHolidays).to receive(:order).with(created_at: :desc).and_return(relation_nil, relation_rec)
    expect(BankHolidaysService).to receive(:new)

    require Rails.root.join("config/business_time")
    BusinessTimeConfig.configure!

    expect(BusinessTime::Config.holidays).to contain_exactly(Date.parse("2026-05-04"))
    expect(BusinessTimeConfig.additional_bank_holidays).to match_array(%w[2026-01-01 2026-11-30])
  end

  it "raises a clear error when bank holidays data remains unavailable" do
    relation_nil = instance_double(ActiveRecord::Relation, first: nil)

    expect(BankHolidays).to receive(:order).with(created_at: :desc).and_return(relation_nil).twice
    expect(BankHolidaysService).to receive(:new)

    require Rails.root.join("config/business_time")
    expect { BusinessTimeConfig.configure! }.to raise_error("Bank holidays data is required but not available")

    # nothing should have been set
    expect(BusinessTime::Config.work_week).to be_nil
    expect(BusinessTime::Config.holidays).to be_nil
    expect(BusinessTimeConfig.additional_bank_holidays).to be_nil
  end

  it "exposes a reader for additional_bank_holidays that returns the current value" do
    record = build_record(ew_dates: %w[2026-08-31], extra_dates: %w[2026-01-01 2026-12-25])
    relation = instance_double(ActiveRecord::Relation, first: record)
    allow(BankHolidays).to receive(:order).with(created_at: :desc).and_return(relation)
    allow(BankHolidaysService).to receive(:new)

    require Rails.root.join("config/business_time")
    BusinessTimeConfig.configure!

    expect(BusinessTimeConfig.additional_bank_holidays).to match_array(%w[2026-01-01 2026-12-25])
  end
end
