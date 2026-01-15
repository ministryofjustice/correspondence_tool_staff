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

    describe "#formatted_dates_for" do
      it "formats dates using the default format" do
        region = "england-and-wales"
        expected = record.dates_for(region).map { |d| Date.iso8601(d).strftime("%d/%m/%Y") }
        expect(record.formatted_dates_for(region)).to eq(expected)
      end

      it "uses a custom format when provided" do
        region = "scotland"
        fmt = "%Y-%m-%d"
        expected = record.dates_for(region).map { |d| Date.iso8601(d).strftime(fmt) }
        expect(record.formatted_dates_for(region, format: fmt)).to eq(expected)
      end

      it "skips invalid date strings during formatting" do
        # Inject an invalid date into a copy of the data under a region that exists
        data = Marshal.load(Marshal.dump(parsed_fixture))
        data["england-and-wales"]["events"] << { "date" => "not-a-date" }
        rec = described_class.new(data: data, hash_value: "with-invalid")

        raw = rec.dates_for("england-and-wales")
        formatted = rec.formatted_dates_for("england-and-wales")
        # One of the raw entries is invalid, so formatted should be strictly smaller
        expect(raw.length).to be > formatted.length
        # All formatted entries should parse with the default format chain we used above
        expect { formatted.each { |s| Date.strptime(s, "%d/%m/%Y") } }.not_to raise_error
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
end
