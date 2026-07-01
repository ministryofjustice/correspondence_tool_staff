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
    let(:event_store) { instance_double(RailsEventStore::Client, publish: true) }
    let(:published_events) { [] }

    before do
      allow(Rails.configuration).to receive(:event_store).and_return(event_store)
      allow(event_store).to receive(:publish) { |event| published_events << event }
    end

    context "when endpoint is unreachable" do
      before { allow(Net::HTTP).to receive(:get).and_raise(StandardError.new("boom")) }

      it "returns an empty hash and does not save a record" do
        allow(Sentry).to receive(:capture_exception)

        service = described_class.new

        expect(service.holidays).to eq({})
        expect(BankHoliday.count).to eq(0)
      end

      it "publishes a BankHolidayIngestFailed event with the error details" do
        allow(Sentry).to receive(:capture_exception)

        described_class.new

        expect(published_events.last).to be_a(Events::BankHolidayIngestFailed)
        expect(published_events.last.data).to include(
          reason: "boom",
          error_class: "StandardError",
        )
      end
    end

    context "when retrieved data is not valid JSON" do
      before { allow(Net::HTTP).to receive(:get).and_return("not-json") }

      it "returns an empty hash and does not save a record" do
        allow(Sentry).to receive(:capture_exception)

        service = described_class.new

        expect(service.holidays).to eq({})
        expect(BankHoliday.count).to eq(0)
      end

      it "publishes a BankHolidayIngestFailed event indicating empty data" do
        allow(Sentry).to receive(:capture_exception)

        described_class.new

        expect(published_events.last).to be_a(Events::BankHolidayIngestFailed)
        expect(published_events.last.data).to include(error_class: "JSON::ParserError")
      end
    end
  end

  describe "#backup" do
    context "when ingest succeeded but returned empty JSON (silent failure)" do
      let(:event_store) { instance_double(RailsEventStore::Client, publish: true) }
      let(:published_events) { [] }

      before do
        allow(Net::HTTP).to receive(:get).and_return("{}")
        allow(Rails.configuration).to receive(:event_store).and_return(event_store)
        allow(event_store).to receive(:publish) { |event| published_events << event }
      end

      it "publishes a BankHolidayIngestFailed event indicating empty data" do
        described_class.new

        expect(published_events.last).to be_a(Events::BankHolidayIngestFailed)
        expect(published_events.last.data[:reason]).to eq("ingest returned empty data")
      end

      it "does not save a BankHoliday record" do
        expect { described_class.new }.not_to change(BankHoliday, :count)
      end
    end

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

    it "creates a new record even when data is unchanged when force: true" do
      allow(Net::HTTP).to receive(:get).and_return(fixture_json)
      described_class.new
      expect(BankHoliday.count).to eq(1)

      allow(Net::HTTP).to receive(:get).and_return(fixture_json)
      expect { described_class.new(force: true) }.to change(BankHoliday, :count).by(1)
    end
  end
end
