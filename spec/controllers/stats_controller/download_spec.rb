require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase) { create :case }
  let!(:report_type) { find_or_create :report_type, :r005 }
  let(:manager) { find_or_create :disclosure_bmt_user }

  after(:all)     { ReportType.delete_all }

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
      it 'sends the generated report as an attachment' do
        Timecop.freeze(Date.new(2019, 3, 22)) do
          get :download, params: { id: report_type.id }

          expect(response.headers['Content-Disposition'])
            .to eq 'attachment; filename="r005_monthly_performance_report.xlsx"'
        end
      end
    end
  end
end
