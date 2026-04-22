require "rails_helper"

RSpec.describe Reports::CacheRefresher do
  describe ".call" do
    before do
      ReportsCache.delete_all
      ReportType.delete_all
    end

    it "includes R900 (non-standard) in the cache refresh and stores results" do
      # Create only R900 as a non-standard report type
      r900 = create(:report_type, :r900, standard_report: false)

      # Stub the service class used by R900 so that it returns data and is cacheable
      service_double = instance_double(
        Stats::R900CasesReport,
        run: true,
        background_job?: false,
        persist_results?: true,
        results: { rows: [{ id: 1 }] },
      )

      allow(Stats::R900CasesReport).to receive(:new).and_return(service_double)

      result = described_class.call(logger: Logger.new(nil))

      expect(result[:failures]).to eq(0)
      expect(result[:successes]).to eq(1)

      latest = ReportsCache.latest_for(r900.abbr)
      expect(latest).to be_present
      expect(latest.data).to eq({ "rows" => [{ "id" => 1 }] })
    end

    it "does nothing (and does not raise) when R900 is absent and there are no standard reports" do
      # No ReportType records at all
      result = described_class.call(logger: Logger.new(nil))

      expect(result[:failures]).to eq(0)
      expect(result[:successes]).to eq(0)
      expect(ReportsCache.count).to eq(0)
    end
  end
end
