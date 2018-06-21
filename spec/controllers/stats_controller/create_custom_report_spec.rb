require 'rails_helper'


module Stats
  RSpec.describe StatsController, type: :controller do

    let!(:kase)       { create :case }
    let(:manager)     { create :disclosure_bmt_user }
    let(:report_type) { find_or_create :r003_report_type }

    let(:params)      {{report: {
                        report_type_id: report_type.id,
                        period_start_dd: Date.yesterday.day,
                        period_start_mm: Date.yesterday.month,
                        period_start_yyyy: Date.yesterday.year,
                        period_end_dd: Date.today.day,
                        period_end_mm: Date.today.month,
                        period_end_yyyy: Date.today.year } }}
    let(:report)     { create :r003_report,
                              period_start: Date.yesterday,
                              period_end: Date.today }

    before(:all) do
      require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')
      ReportTypeSeeder.new.seed!
    end

    after(:all) { ReportType.delete_all }

    describe '#create_custom_report' do
      before do
        sign_in manager
      end

      it 'authorizes' do
        expect { post :create_custom_report, params: params }
          .to require_permission(:can_download_stats?)
                .with_args(manager, Case::Base)
      end

      it 'runs the report' do
        expect(Report).to receive(:new).and_return(report)
        allow(report).to receive(:run)
        post :create_custom_report, params: params
        expect(report).to have_received(:run).with(Date.yesterday,
                                                   Date.today)
      end

      it 'populates the report_data column' do
        post :create_custom_report, params: params
        new_report= assigns(:report)
        expect(new_report.report_data).to_not be_nil
      end

      it 'creates an entry in the database' do
        total = Report.count
        post :create_custom_report, params: params
        expect(Report.count).to eq total + 1
      end

      context 'invalid params passed in' do
        let(:params) {{report: { report_type_id: report_type.id,
                                  period_start_dd: nil,
                                  period_start_mm: nil,
                                  period_start_yyyy: nil,
                                  period_end_dd: nil,
                                  period_end_mm: nil,
                                  period_end_yyyy: nil}}}

        it 'sets @report to the values that were passed in' do
          post :create_custom_report, params: params
          expect(assigns(:report)).to be_new_record

        end
        it 'sets @custom_reports_foi' do
          post :create_custom_report, params: params
          expect(assigns(:custom_reports_foi)).to eq ReportType.custom.foi
        end

        it 'sets @custom_reports_sar' do
          post :create_custom_report, params: params
          expect(assigns(:custom_reports_sar)).to eq ReportType.custom.sar
        end

        it 'renders the template' do
          post :create_custom_report, params: params
          expect(response).to render_template(:custom)
        end

        it 'returns 2 errors (dates are missing)' do
          post :create_custom_report, params: params
          expect(assigns(:report).errors.count).to eq 2
        end
      end

    end
  end
end
