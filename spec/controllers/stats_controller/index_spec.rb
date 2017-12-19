require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)    { create :case}
  let(:manager) { create :disclosure_bmt_user }

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
              .with_args(manager, kase)
    end

    it 'sets @reports' do
      get :index
      expect(assigns(:reports)).to eq ReportType.all.order(:seq_id)
    end

    it 'renders the template' do
      get :index
      expect(response).to render_template(:index)
    end
  end
end
