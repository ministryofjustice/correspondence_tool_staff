require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)             { create :case }
  let!(:r005_report_type) { create :report_type, :r005 }
  let(:manager)           { find_or_create :disclosure_bmt_user }

  describe '#download' do
    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :download, params: { id: ReportType.first.id  }}
        .to require_permission(:can_download_stats?)
              .with_args(manager, Case::Base)
    end

    context 'there is no already-generated report' do
      let(:report_type) { find_or_create :report_type, :r005 }

      it 'generates a new report' do
        expect {
          get :download, params: { id: report_type.id }
        }.to change(Report, :count).by(1)
        new_report = Report.last
        expect(new_report.report_type).to eq report_type
      end

      it 'sends the generated report as an attachment' do
        Timecop.freeze(Date.new(2019, 3, 22)) do
          get :download, params: { id: report_type.id }

          expect(response.body)
            .to eq [
                     ['Monthly report - 1 Jan 2019 to 22 Mar 2019'],
                     [''] + ['Non-trigger cases'] * 6 + ['Trigger cases'] * 6 + ["Overall"] * 6,
                     ['Month','Performance %','Total received','Responded - in time',
                      'Responded - late','Open - in time','Open - late','Performance %',
                      'Total received','Responded - in time','Responded - late','Open - in time',
                      'Open - late','Performance %','Total received','Responded - in time',
                      'Responded - late','Open - in time','Open - late'],
                     ['January', 0.0,0,0,0,0,0,0.0,0,0,0,0,0,0.0,0,0,0,0,0],
                     ['February', 0.0,0,0,0,0,0,0.0,0,0,0,0,0,0.0,0,0,0,0,0],
                     ['March', 0.0,0,0,0,0,0,0.0,0,0,0,0,0,0.0,0,0,0,0,0],
                     ['Total', 0.0,0,0,0,0,0,0.0,0,0,0,0,0,0.0,0,0,0,0,0],
                   ].map { |h| CSV.generate_line(h) }.join
          expect(response.headers['Content-Disposition'])
            .to eq 'attachment; filename="r005_monthly_performance_report.csv"'
        end
      end
    end

    context 'there is an old already-generated report' do
      let(:report_type) { find_or_create :report_type, :r005 }

      before do
        create :r005_report, created_at: 1.days.ago
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
          .to eq 'attachment; filename="r005_monthly_performance_report.csv"'
      end
    end

    context 'there is no scheduled job for the given report' do
      let(:report_type) { find_or_create :report_type, :r003 }

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
