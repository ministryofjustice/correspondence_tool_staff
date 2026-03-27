require "rails_helper"

RSpec.describe BankHolidaysService, type: :service do
  let(:fixture_json) { File.read(Rails.root.join("spec/fixtures/bank_holidays_response.json")) }
  let(:parsed_fixture) { JSON.parse(fixture_json) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe "#initialize" do
    it "fetches and parses JSON into #holidays and performs a backup" do
      allow(Net::HTTP).to receive(:get).and_return(fixture_json)

      expect { described_class.new }.to change(BankHoliday, :count).by(1)
      service = described_class.new # null_store cache means it will refetch each time in test env

      expect(service.holidays).to be_a(Hash)
      expect(service.holidays.keys).to match_array(%w[england-and-wales northern-ireland scotland])
      expect(service.holidays).to eq(parsed_fixture)
    end

    it "sets Sentry context" do
      allow(Net::HTTP).to receive(:get).and_return(fixture_json)
      allow(SentryContextProvider).to receive(:set_context)

      described_class.new

      expect(SentryContextProvider).to have_received(:set_context)
    end
  end

  describe "#ingest" do
    context "when endpoint is unreachable" do
      it "returns an empty hash" do
        allow(Net::HTTP).to receive(:get).and_raise(StandardError.new("boom"))
        expect(Sentry).to receive(:capture_exception).with(StandardError)

        service = described_class.new

        expect(service.holidays).to eq({})
        expect(BankHoliday.count).to eq(0)
      end
    end

    context "when retrieved data is not valid JSON" do
      it "returns an empty hash" do
        allow(Net::HTTP).to receive(:get).and_return("not-json")
        expect(Sentry).to receive(:capture_exception).with(JSON::ParserError)

        service = described_class.new

        expect(service.holidays).to eq({})
        # No backup should occur if there is no data
        expect(BankHoliday.count).to eq(0)
      end
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
