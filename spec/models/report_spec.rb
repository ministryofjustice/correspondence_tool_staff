require 'rails_helper'

RSpec.describe Report, type: :model do
  before do
    ReportType.destroy_all
  end

  let!(:r003_report_type) { find_or_create(:report_type, :r003) }

  describe 'report_type_id' do
    it { should belong_to(:report_type) }
  end

  describe 'mandatory fields' do
    it 'should require the following fields' do
      should validate_presence_of(:report_type_id)
    end
  end

  describe '#report_type_abbr=' do
    it 'finds a report_type by abbreviation' do
      r003_report_type = find_or_create(:report_type, :r003)
      report = Report.new(report_type_abbr: 'R003')
      expect(report.report_type_id).to eq r003_report_type.id
    end
  end

  describe '#period_start' do
    let(:tomorrow) {
      build(
        :report,
        period_start: Date.tomorrow.to_s,
        report_type: r003_report_type
      )
    }

    let(:today) {
      build(
        :report,
        period_start: Date.today.to_s,
        period_end: Date.today.to_s,
        report_type: r003_report_type
      )
    }

    let(:yesterday) {
      build(
        :report,
        period_start: Date.yesterday.to_s,
        period_end: Date.today.to_s,
        report_type: r003_report_type
      )
    }

    let(:after_period_end) {
      build(
        :report,
        period_start: Date.today.to_s,
        period_end: Date.yesterday.to_s,
        report_type: r003_report_type
      )
    }

    it 'cannot be in the future' do
      expect(tomorrow).to_not be_valid
    end

    it 'can be for today' do
      expect(today).to be_valid
    end

    it 'can be in the past' do
      expect(yesterday).to be_valid
    end

    it 'cannot after period end' do
      expect(after_period_end).to_not be_valid
    end
  end

  describe '#period_end' do
    let(:tomorrow) {
      build_stubbed(
        :report,
        period_end: Date.tomorrow.to_s
      )
    }

    let(:today) {
      build_stubbed(
        :report,
        period_start: Date.today.to_s,
        period_end: Date.today.to_s
      )
    }

    let(:yesterday) {
      build_stubbed(
        :report,
        period_end: Date.yesterday.to_s
      )
    }

    it "can't be in the future" do
      expect(tomorrow).to_not be_valid
    end

    it "can be for today" do
      expect(today).to be_valid
    end

    it 'can be in the past' do
      expect(yesterday).to be_valid
    end
  end

  describe '#run' do
    let(:options) {{ period_start: Date.yesterday, period_end: Date.today }}

    let(:report_service) {
      instance_double(
        Stats::R003BusinessUnitPerformanceReport,
        to_csv: [
          [
            OpenStruct.new(value: 'report'),
            OpenStruct.new(value: 'data')
          ]
        ],
        period_start: Date.yesterday,
        period_end: Date.today,
        run: true,
        persist_results?: true,
      )
    }

    let(:report) { create :r003_report }

    before do
      expect(Stats::R003BusinessUnitPerformanceReport)
        .to receive(:new).with(**options).and_return(report_service)
    end

    it 'saves report when ReportService.persist_results? and then runs' do
      expect(report).to receive(:save!)
      report.run_and_update!(**options)
      expect(report_service).to have_received(:run)
    end

    it 'updates start and end dates' do
      report.run_and_update!(**options)
      expect(report.period_start).to eq Date.yesterday
      expect(report.period_end).to   eq Date.today
    end

    it 'updates the report_data' do
      report.run_and_update!(**options)
      expect(report.report_data).to eq "\"report\",\"data\"\n"
    end
  end

  describe '#run_and_update!' do
    context 'etl' do
      let(:etl_report_type) {
        instance_double(
          Stats::R007ClosedCasesReport,
          period_start: Date.yesterday,
          period_end: Date.today,
          run: true,
          persist_results?: true,
          etl?: true,
        )
      }

      it 'saves JSON in report_data' do
        new_report = create :r007_report

        expect(etl_report_type.etl?).to eq true
        expect(new_report).to receive(:save!)
        json = JSON.parse(new_report.report_data, symbolize_names: true)
        expect(json[:status]).to eq Report::WAITING
        new_report.run_and_update!(user: OpenStruct.new(id: 1), some: 'value')
      end
    end
  end
end
