require "rails_helper"

RSpec.describe Report, type: :model do
  before do
    ReportType.destroy_all
  end

  let!(:r003_report_type) { find_or_create(:report_type, :r003) }

  describe "report_type_id" do
    it { is_expected.to belong_to(:report_type) }
  end

  describe "mandatory fields" do
    it "requires the following fields" do
      expect(described_class.new).to validate_presence_of(:report_type_id)
    end
  end

  describe "#report_type_abbr=" do
    it "finds a report_type by abbreviation" do
      r003_report_type = find_or_create(:report_type, :r003)
      report = described_class.new(report_type_abbr: "R003")
      expect(report.report_type_id).to eq r003_report_type.id
    end
  end

  describe "#period_start" do
    let(:tomorrow) do
      build(
        :report,
        period_start: Time.zone.tomorrow.to_s,
        report_type: r003_report_type,
      )
    end

    let(:today) do
      build(
        :report,
        period_start: Time.zone.today.to_s,
        period_end: Time.zone.today.to_s,
        report_type: r003_report_type,
      )
    end

    let(:yesterday) do
      build(
        :report,
        period_start: Time.zone.yesterday.to_s,
        period_end: Time.zone.today.to_s,
        report_type: r003_report_type,
      )
    end

    let(:after_period_end) do
      build(
        :report,
        period_start: Time.zone.today.to_s,
        period_end: Time.zone.yesterday.to_s,
        report_type: r003_report_type,
      )
    end

    it "cannot be in the future" do
      expect(tomorrow).not_to be_valid
    end

    it "can be for today" do
      expect(today).to be_valid
    end

    it "can be in the past" do
      expect(yesterday).to be_valid
    end

    it "cannot after period end" do
      expect(after_period_end).not_to be_valid
    end
  end

  describe "#period_end" do
    let(:tomorrow) do
      build_stubbed(
        :report,
        period_end: Time.zone.tomorrow.to_s,
      )
    end

    let(:today) do
      build_stubbed(
        :report,
        period_start: Time.zone.today.to_s,
        period_end: Time.zone.today.to_s,
      )
    end

    let(:yesterday) do
      build_stubbed(
        :report,
        period_end: Time.zone.yesterday.to_s,
      )
    end

    it "cannot be in the future" do
      expect(tomorrow).not_to be_valid
    end

    it "can be for today" do
      expect(today).to be_valid
    end

    it "can be in the past" do
      expect(yesterday).to be_valid
    end
  end

  describe "#run" do
    let(:options) { { period_start: Time.zone.yesterday, period_end: Time.zone.today } }

    let(:report_service) do
      instance_double(
        Stats::R003BusinessUnitPerformanceReport,
        to_csv: [
          [
            OpenStruct.new(value: "report"),
            OpenStruct.new(value: "data"),
          ],
        ],
        period_start: Time.zone.yesterday,
        period_end: Time.zone.today,
        run: true,
        persist_results?: true,
        background_job?: true,
        etl?: false,
      )
    end

    let(:report) { create :r003_report }
    let(:report_data) { { "report": "data" } }

    before do
      allow(Stats::R003BusinessUnitPerformanceReport)
        .to receive(:new).with(**options).and_return(report_service)
      allow(report_service).to receive(:background_job?).and_return(false)
      allow(report_service).to receive(:results).and_return(report_data)
      allow(report_service).to receive(:filename).and_return(nil)
      allow(report_service).to receive(:user).and_return(nil)
      allow(report_service).to receive(:report_format).and_return("csv")
    end

    it "saves report when ReportService.persist_results? and then runs" do
      expect(report).to receive(:save!)
      report.run_and_update!(**options)
      expect(report_service).to have_received(:run)
    end

    it "updates start and end dates" do
      report.run_and_update!(**options)
      expect(report.period_start).to eq Time.zone.yesterday
      expect(report.period_end).to   eq Time.zone.today
    end

    it "updates the report_data" do
      report.run_and_update!(**options)
      expect(report.report_data).to eq report_data.to_json
    end
  end

  describe "#run_and_update!" do
    context "when etl" do
      let(:etl_report_type) do
        instance_double(
          Stats::R007ClosedCasesReport,
          period_start: Time.zone.yesterday,
          period_end: Time.zone.today,
          run: true,
          persist_results?: true,
          etl?: true,
        )
      end

      it "saves JSON in report_data" do
        new_report = create :r007_report

        expect(etl_report_type.etl?).to eq true
        expect(new_report).to receive(:save!)
        json = JSON.parse(new_report.report_data, symbolize_names: true)
        expect(json[:status]).to eq Stats::BaseReport::WAITING
        new_report.run_and_update!(user: OpenStruct.new(id: 1), some: "value")
      end
    end
  end
end
