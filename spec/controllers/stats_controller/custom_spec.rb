require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)    { create :case}
  let(:manager) { create :disclosure_bmt_user }

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

    it 'sets @custom_reports_sar' do
      get :custom
      expect(assigns(:correspondence_types)).to eq CorrespondenceType.all
    end

    it 'renders the template' do
      get :custom
      expect(response).to render_template(:custom)
    end

    context 'setting default correspondence type' do
      before do
        # override whatever is in the settings file with these settings
        Settings.enabled_features.sars = Config::Options.new({
                                                             :"Local" => false,
                                                             :"Host-dev" => false,
                                                             :"Host-demo" => false,
                                                             :"Host-staging" => false,
                                                             :"Host-production" => false
                                                         })
      end
      it 'sets the correspondence type to FOI if sars is not enabled' do
        get :custom
        expect(assigns(:report).correspondence_type).to eq 'FOI'
      end
    end


  end
end
