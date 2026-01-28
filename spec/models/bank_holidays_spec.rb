require "rails_helper"

RSpec.describe BankHolidays, type: :model do
  let(:fixture_json) { File.read(Rails.root.join("spec/fixtures/bank_holidays_response.json")) }
  let(:parsed_fixture) { JSON.parse(fixture_json) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:data) }
    it { is_expected.to validate_presence_of(:hash_value) }
  end

  describe "behaviour with Hash data" do
    subject(:record) { described_class.new(data: parsed_fixture, hash_value: "abc123") }

    it "is valid with data and hash_value" do
      expect(record).to be_valid
    end

    describe "#dates_for" do
      it "returns raw ISO8601 date strings for a known hyphenated region" do
        region = "england-and-wales"
        expected = parsed_fixture[region]["events"].map { |e| e["date"] }.compact
        expect(record.dates_for(region)).to eq(expected)
      end

      it "accepts underscore region names by normalising to hyphens" do
        hyphen_region = "england-and-wales"
        underscore_region = :england_and_wales
        expect(record.dates_for(underscore_region)).to eq(record.dates_for(hyphen_region))
      end

      it "returns [] for unknown regions" do
        expect(record.dates_for("unknown-region")).to eq([])
      end

      it "returns [] for nil region" do
        expect(record.dates_for(nil)).to eq([])
      end
    end

    describe "#dates_for_regions" do
      it "combines dates for multiple regions and de-duplicates them" do
        r1 = "england-and-wales"
        r2 = "scotland"
        combined = (record.dates_for(r1) + record.dates_for(r2)).uniq
        expect(record.dates_for_regions(r1, r2)).to match_array(combined)
      end

      it "ignores nil/blank inputs" do
        r1 = "england-and-wales"
        expect(record.dates_for_regions(r1, nil, "")).to match_array(record.dates_for(r1))
      end
    end
  end

  describe "behaviour with String JSON data" do
    subject(:record) { described_class.new(data: fixture_json, hash_value: "jsonstr") }

    it "parses data from a String and behaves the same" do
      expect(record).to be_valid
      region = "northern-ireland"
      expected = parsed_fixture[region]["events"].map { |e| e["date"] }.compact
      expect(record.dates_for(region)).to eq(expected)
    end
  end

  describe ".bank_holiday?" do
    before do
      described_class.delete_all
      described_class.create!(data: parsed_fixture, hash_value: "hash1")
    end

    it "returns true for a date present in any region by default (:all)" do
      scotland_date = parsed_fixture["scotland"]["events"].first["date"]
      expect(described_class.bank_holiday?(scotland_date)).to be(true)
    end

    it "respects explicit regions filter" do
      ew_dates = parsed_fixture["england-and-wales"]["events"].map { |e| e["date"] }
      ni_dates = parsed_fixture["northern-ireland"]["events"].map { |e| e["date"] }
      ni_only_date = (ni_dates - ew_dates).first
      # Sanity check in case fixtures change: fall back to a known NI-specific date
      ni_only_date ||= "2019-03-18" # St Patrick's Day substitute (example in fixtures)

      expect(described_class.bank_holiday?(ni_only_date, regions: [:england_and_wales])).to be(false)
      expect(described_class.bank_holiday?(ni_only_date, regions: [:northern_ireland])).to be(true)
    end
  end
end
