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
      it 'sets the correspondence type to FOI if sars is not enabled' do
        allow(FeatureSet).to receive(:sars).and_return(double 'FeatureSet-Sars', enabled?: false, disabled?: true)
        get :custom
        expect(assigns(:report).correspondence_type).to eq 'FOI'
      end
    end

  end
end
