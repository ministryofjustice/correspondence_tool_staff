require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)   { create :case }
  let(:manager) { create :disclosure_bmt_user }

  describe '#download' do
    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :download, params: { id: ReportType.first.id  }}
        .to require_permission(:can_download_stats?)
              .with_args(manager, kase)
    end

    context 'there is an already-generated report' do
      let!(:report)     { create :r003_report }
      let(:report_type) { report.report_type }

      it 'responds with existing report data' do
        get :download, params: { id: report_type.id }
        expect(response.headers['Content-Disposition'])
          .to eq 'attachment; filename="r003_business_unit_performance_report.csv"'
        expect(response.body).to eq report.report_data
      end
    end

    context 'there is no already-generated report' do
      let(:report_type) { find_or_create :r003_report_type }

      it 'generates a new report' do
        existing_count = Report.count
        get :download, params: { id: report_type.id }
        expect(Report.count).to eq existing_count + 1
        new_report = Report.last
        expect(new_report.report_type).to eq report_type
      end

      it 'sends the generated report as an attachment' do
        get :download, params: { id: report_type.id }
        new_report = Report.last
        expect(response.body).to eq new_report.report_data
        expect(response.headers['Content-Disposition'])
          .to eq 'attachment; filename="r003_business_unit_performance_report.csv"'
      end
    end

    context 'there is an old already-generated report' do
      let(:report_type) { find_or_create :r003_report_type }

      before do
        create :r003_report, created_at: 1.days.ago
      end

      it 'generates a new report' do
        existing_report = Report.where(report_type_id: report_type.id).last
        get :download, params: { id: report_type.id }
        new_report = Report.last
        expect(new_report.report_type).to eq report_type
        expect(new_report.id).not_to eq existing_report.id
        expect(new_report.created_at).to be > existing_report.created_at
      end

      it 'sends the generated report as an attachment' do
        get :download, params: { id: report_type.id }
        new_report = Report.last
        expect(response.body).to eq new_report.report_data
        expect(response.headers['Content-Disposition'])
          .to eq 'attachment; filename="r003_business_unit_performance_report.csv"'
      end
    end

    context 'there is no scheduled job for the given report' do
      let(:report_type) { find_or_create :r003_report_type }

      before do
        allow(YAML).to receive(:load_file).and_return <<~EOYML
          ---
          :schedule:
          EOYML
      end

      it 'generates a new report' do
        existing_count = Report.count
        get :download, params: { id: report_type.id }
        expect(Report.count).to eq existing_count + 1
        new_report = Report.last
        expect(new_report.report_type).to eq report_type
      end

      it 'sends the generated report as an attachment' do
        get :download, params: { id: report_type.id }
        new_report = Report.last
        expect(response.body).to eq new_report.report_data
        expect(response.headers['Content-Disposition'])
          .to eq 'attachment; filename="r003_business_unit_performance_report.csv"'
      end
    end
  end
end
