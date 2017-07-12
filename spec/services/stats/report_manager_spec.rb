require 'rails_helper'

module Stats
  describe ReportManager do

    let(:manager)  { ReportManager.new}

    describe '#reports' do
      it 'returns a hash of reports indexed by report_id' do
        expect(manager.reports).to eq ReportManager::REPORTS
      end
    end

    describe '#report_class' do
      it 'returns the class of the report with the given index' do
        expect(manager.report_class('R003')).to eq R003BusinessUnitPerformanceReport
      end
    end

    describe '#report_object' do
      it 'returns an instantiated oject' do
        expect(manager.report_object('R003')).to be_instance_of(R003BusinessUnitPerformanceReport)
      end
    end

    describe '#filename' do
      it 'returns the filename for the given report' do
        expect(manager.filename('R003')).to eq 'r003_business_unit_performance_report.csv'
      end
    end
  end
end

