require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)    { create :case}
  let(:manager) { find_or_create :disclosure_bmt_user }

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')
    ReportTypeSeeder.new.seed!
  end

  after(:all) { ReportType.delete_all }

  describe '#custom' do
    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :custom }
        .to require_permission(:can_download_stats?)
              .with_args(manager, Case::Base)
    end

    it 'sets @report' do
      get :custom
      expect(assigns(:report)).to be_new_record
    end

    it 'sets @custom_reports_foi' do
      get :custom
      expect(assigns(:custom_reports_foi)).to eq ReportType.custom.foi
    end

    it 'sets @custom_reports_sar' do
      get :custom
      expect(assigns(:custom_reports_sar)).to eq ReportType.custom.sar
    end

    it 'sets @correspondence_types' do
      get :custom
      expect(assigns(:correspondence_types)).to eq CorrespondenceType.custom_reporting_types
    end

    it 'renders the template' do
      get :custom
      expect(response).to render_template(:custom)
    end
  end
end
