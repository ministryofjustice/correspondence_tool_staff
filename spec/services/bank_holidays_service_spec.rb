require "rails_helper"

RSpec.describe BankHolidaysService do
  let(:fixture_data) { File.read("spec/fixtures/bank_holidays_response.json") }
  let(:parsed_data) { JSON.parse(fixture_data) }
  let(:bank_holidays) { described_class.new }

  before do
    allow(Net::HTTP).to receive(:get)
                          .with(URI(described_class::URL))
                          .and_return(fixture_data)
  end

  describe "#initialize" do
    it "fetches and stores holidays data" do
      expect(bank_holidays.holidays).to eq(parsed_data)
    end
  end

  describe "#get_bank_holidays_for" do
    %w[england-and-wales scotland northern-ireland].each do |division|
      context "when division is '#{division}'" do
        it "returns holidays for the division" do
          expect(bank_holidays.get_bank_holidays_for(division)).to eq(parsed_data[division]["events"])
        end
      end
    end

    context "when division does not exist" do
      it "returns an empty array" do
        expect(bank_holidays.get_bank_holidays_for("unknown")).to eq([])
      end
    end
  end

  describe "#backup" do
    it "calls update! for each event" do
      bank_holiday_double = double(update!: true)
      allow(BankHolidays).to receive(:find_or_initialize_by).and_return(bank_holiday_double)
      expect(bank_holiday_double).to receive(:update!).at_least(:once)
      bank_holidays.backup
    end
  end
end
