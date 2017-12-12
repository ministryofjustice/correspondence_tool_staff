require 'rails_helper'

describe ReportGeneratorJob do

  let(:report_date)    { Time.local(2017, 12, 11, 15, 35, 6) }

  context 'R003' do

    before(:each) { create :report_type, :r003 }

    context 'not specifying a period' do

      it 'generates the report' do
        Timecop.freeze report_date do
          ReportGeneratorJob.perform_now('R003')
          report = Report.last_by_abbr('R003')
          expect(report.report_data).not_to be_nil
          expect(report.report_data).to match(/^Business unit report - 1 Jan 2017 to 11 Dec 2017/)
        end
      end

      it 'updates the period start and end on the report record' do
        Timecop.freeze report_date do
          ReportGeneratorJob.perform_now('R003')
        end
        report_record = Report.last_by_abbr('R003')
        expect(report_record.period_start).to eq Date.new(2017, 1, 1)
        expect(report_record.period_end).to eq Date.new(2017, 12, 11)
      end
    end

    context 'period start and end are passsed to the generator' do
      let(:period_start)    { Date.new(2017, 6, 1) }
      let(:period_end)      { Date.new(2017, 6, 30) }

      it 'generates the report' do
        ReportGeneratorJob.perform_now('R003', period_start, period_end)
        report = Report.last_by_abbr('R003')
        expect(report.report_data).not_to be_nil
        expect(report.report_data).to match(/^Business unit report - 1 Jun 2017 to 30 Jun 2017/)
      end

      it 'updates the period start and end on the report record' do
        ReportGeneratorJob.perform_now('R003', period_start, period_end)
        report_record = Report.last_by_abbr('R003')
        expect(report_record.period_start).to eq Date.new(2017, 6, 1)
        expect(report_record.period_end).to eq Date.new(2017, 6, 30)
      end

    end

  end



end
