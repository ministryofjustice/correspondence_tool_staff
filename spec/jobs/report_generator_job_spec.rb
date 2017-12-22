require 'rails_helper'

describe ReportGeneratorJob do
  let!(:r003_report_type) { find_or_create(:r003_report_type) }
  let!(:r004_report_type) { find_or_create(:r004_report_type) }

  it 'sets the Raven context' do
    expect(RavenContextProvider).to receive(:set_context)
    ReportGeneratorJob.perform_now('R003')
  end

  context 'report object creation' do
    let(:report_record) { instance_spy(Report) }
    let(:report_where)  { instance_spy(Report::ActiveRecord_Relation) }

    before do
      allow(Report).to receive(:new).and_return(report_record)
      allow(Report).to receive(:where).and_return(report_where)
    end

    it 'creates a report object and calls run on it' do
      expect(Report).to receive(:new).and_return(report_record)
      ReportGeneratorJob.perform_now('R003', :arg1, :arg2)
      expect(report_record).to have_received(:run).with(:arg1, :arg2)
    end
  end

  it 'removes previous reports' do
    r003_report = create(:r003_report)
    r004_report = create(:r004_report)
    ReportGeneratorJob.perform_now('R003')
    expect(Report.exists?(r003_report.id)).to eq false
    expect(Report.exists?(r004_report.id)).to eq true
  end
end
