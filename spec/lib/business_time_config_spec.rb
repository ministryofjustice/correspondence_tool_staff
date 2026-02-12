require "rails_helper"

RSpec.describe BusinessTimeConfig do
  context "with real bank holiday data" do
    describe ".configure!" do
      it "has been loaded by the application" do
        expect(BusinessTime::Config.holidays.size).to be > 50
        expect(BusinessTime::Config.work_week).to eq(%w[mon tue wed thu fri])
      end

      it "is loaded with appropriate data types" do
        expect(BusinessTime::Config.holidays).to all(be_a(Date))
      end

      it "contains dates spanning at least 3 years and this year" do
        dates = BusinessTime::Config.holidays.sort.map(&:year)

        expect(dates.first).to be < Time.zone.today.year
        expect(dates.last).to be > Time.zone.today.year

        #  8 holidays per year typically in England & Wales
        expect(dates.select { |year| year == Time.zone.today.year }.size).to be >= 8
      end
    end

    describe "#additional_bank_holidays" do
      it "has been loaded by the application" do
        expect(described_class.additional_bank_holidays.size).to be > 50
      end

      it "is loaded with appropriate data types" do
        expect(described_class.additional_bank_holidays).to all(be_a(String))
        expect(described_class.additional_bank_holidays).to be_frozen
      end
    end
  end

  context "with mock bank holiday data" do
    before do
      truncated_api_response = File.read(Rails.root.join("spec/fixtures/bank_holidays_response_truncated.json"))

      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(BankHolidaysService).to receive(:fetch_holidays).and_return(truncated_api_response)
      # rubocop:enable RSpec/AnyInstance

      described_class.configure!
    end

    after do
      # Reload real data
      described_class.configure!
    end

    describe ".configure!" do
      it "has valid holidays" do
        england_and_wales_holidays = %w[2026-01-01 2026-04-03 2026-12-25].map { |date| Date.parse(date) }

        expect(BusinessTime::Config.holidays).to all(be_a(Date))
        expect(BusinessTime::Config.holidays).to eq(england_and_wales_holidays)
      end

      context "with no persisted bank holiday data" do
        before do
          record = instance_double(
            BankHoliday,
            dates_for: %w[2027-03-25 2027-04-28],
            dates_for_regions: %w[2027-09-01],
          )

          allow(BankHoliday).to receive(:order).at_least(:twice).and_return(
            instance_double(ActiveRecord::Relation, first: nil),
            instance_double(ActiveRecord::Relation, first: record),
          )

          described_class.configure!
        end

        it "attempts 1 bank holiday data reload" do
          expect(BusinessTime::Config.holidays).to contain_exactly(Date.parse("2027-03-25"), Date.parse("2027-04-28"))
        end
      end

      context "with no data available at all" do
        before do
          BusinessTime::Config.work_week = nil
          BusinessTime::Config.holidays = nil

          record = instance_double(
            BankHoliday,
            dates_for: %w[2027-03-25 2027-04-28],
            dates_for_regions: %w[2027-09-01],
          )

          allow(BankHoliday).to receive(:order).at_least(:twice).and_return(
            instance_double(ActiveRecord::Relation, first: nil), # 1st attempt
            instance_double(ActiveRecord::Relation, first: nil), # 2nd attempt
            instance_double(ActiveRecord::Relation, first: record), # For other tests need data
          )
        end

        it "throws exception" do
          expect { described_class.configure! }.to raise_error("Bank holidays data is required but not available")

          expect(BusinessTime::Config.work_week).to be_nil
          expect(BusinessTime::Config.holidays).to be_nil
        end
      end
    end

    describe "#additional_bank_holidays" do
      it "has valid Scottish and Northern Irish holidays" do
        scotland_and_ni_holidays = %w[2026-01-01 2026-01-02 2026-03-17 2026-07-13]

        expect(described_class.additional_bank_holidays).to all(be_a(String))
        expect(described_class.additional_bank_holidays).to eq(scotland_and_ni_holidays)
      end
    end
  end
end
