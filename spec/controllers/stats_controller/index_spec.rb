require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)    { create :case}
  let(:manager) { find_or_create :disclosure_bmt_user }

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')
    ReportTypeSeeder.new.seed!
  end

  after(:all) { ReportType.delete_all }

  describe '#index' do
    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :index }
        .to require_permission(:can_download_stats?)
              .with_args(manager, Case::Base)
    end

    it 'sets @foi_reports' do
      get :index
      expect(assigns(:foi_reports)).to eq ReportType.standard.foi.order(:full_name)
    end

    it 'sets @sar_reports' do
      get :index
      expect(assigns(:sar_reports)).to eq ReportType.standard.sar.order(:full_name)
    end

    it 'renders the template' do
      get :index
      expect(response).to render_template(:index)
    end
  end
end
