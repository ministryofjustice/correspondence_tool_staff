require 'rails_helper'

describe ReportGeneratorJob do

  let(:report_date)    { Time.local(2017, 12, 11, 15, 35, 6) }

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
    require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')
    CaseClosure::MetadataSeeder.seed!
    ReportTypeSeeder.new.seed!
  end

  after(:all) do
    ReportType.destroy_all
    CaseClosure::Metadatum.destroy_all
  end

  context 'R003' do

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

      it 'sets the report period start and end from the passed in params' do
        ReportGeneratorJob.perform_now('R003', period_start, period_end)
        report_record = Report.last_by_abbr('R003')
        expect(report_record.period_start).to eq Date.new(2017, 6, 1)
        expect(report_record.period_end).to eq Date.new(2017, 6, 30)
      end
    end
  end

  context 'R004' do
    context 'not specifying a time period' do

      let(:quarter_start) { Date.new(2017, 10, 1) }

      it 'creates the report' do
        Timecop.freeze(report_date) do
          ReportGeneratorJob.perform_now('R004')
        end
        report = Report.last_by_abbr('R004')
        expect(report.report_data).not_to be_nil
        expect(report.report_data).to match(/\ADated: 11 Dec 2017\nFor period 1 Oct 2017 to 11 Dec 2017\nCabinet office report/)
      end

      it 'sets the report period start and end from the beginning of the quarter until today' do
        Timecop.freeze(report_date) do
          ReportGeneratorJob.perform_now('R004')
        end
        report = Report.last_by_abbr('R004')
        expect(report.period_start).to eq quarter_start
        expect(report.period_end).to eq report_date.to_date
      end
    end

    context 'passing in parameter dates' do
      it raises
    end

  end



end
