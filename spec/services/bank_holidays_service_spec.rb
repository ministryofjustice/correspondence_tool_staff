require "rails_helper"

RSpec.describe BankHolidaysService, type: :service do
  let(:fixture_json) { File.read(Rails.root.join("spec/fixtures/bank_holidays_response.json")) }
  let(:parsed_fixture) { JSON.parse(fixture_json) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe "initialisation" do
    it "fetches and parses JSON into #holidays and performs a backup" do
      allow(Net::HTTP).to receive(:get).and_return(fixture_json)

      expect { described_class.new }.to change(BankHoliday, :count).by(1)
      service = described_class.new # null_store cache means it will refetch each time in test env

      expect(service.holidays).to be_a(Hash)
      # spot-check a known top-level key from the fixture
      expect(service.holidays.keys).to include("england-and-wales")
      expect(service.holidays).to eq(parsed_fixture)
    end
  end

  describe "loading" do
    it "returns an empty hash and does not raise when JSON is invalid" do
      allow(Net::HTTP).to receive(:get).and_return("not-json")
      service = described_class.new

      expect(service.holidays).to eq({})
      # No backup should occur if there is no data
      expect(BankHoliday.count).to eq(0)
      expect(Rails.logger).to have_received(:error).with(/Failed to parse bank holidays JSON/)
    end

    it "returns an empty hash when network fetch fails" do
      allow(Net::HTTP).to receive(:get).and_raise(StandardError.new("boom"))
      service = described_class.new

      expect(service.holidays).to eq({})
      expect(BankHoliday.count).to eq(0)
      expect(Rails.logger).to have_received(:error).with(/Failed to fetch bank holidays/)
    end

    it "returns an empty hash when remote returns blank body" do
      allow(Net::HTTP).to receive(:get).and_return("")
      service = described_class.new

      expect(service.holidays).to eq({})
      expect(BankHoliday.count).to eq(0)
    end
  end

  describe "#backup" do
    it "creates a new record when data changes and skips duplicates" do
      # First load stores initial snapshot
      allow(Net::HTTP).to receive(:get).and_return(fixture_json)
      first_service = described_class.new
      expect(first_service.holidays).to eq(parsed_fixture)
      expect(BankHoliday.count).to eq(1)

      # Second load with identical data shouldn't create another record
      allow(Net::HTTP).to receive(:get).and_return(fixture_json)
      expect { described_class.new }.not_to change(BankHoliday, :count)

      # Third load with modified data should create a new record
      mutated = JSON.parse(fixture_json)
      mutated["england-and-wales"]["events"] << { "title" => "Test Day", "date" => "2099-01-01" }
      allow(Net::HTTP).to receive(:get).and_return(mutated.to_json)

      expect { described_class.new }.to change(BankHoliday, :count).by(1)
    end
  end
end
