require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)    { create :case }
  let(:manager) { create :disclosure_bmt_user }

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')
    ReportTypeSeeder.new.seed!
  end

  after(:all) { ReportType.delete_all }

  describe '#download' do
    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :download, params: { id: ReportType.first.id  }}
        .to require_permission(:can_download_stats?)
              .with_args(manager, kase)
    end

    it 'responds with a csv' do
      file_options = {filename: "#{ReportType.first.class_name.underscore.to_s.underscore.sub('stats/', '')}.csv"}
      report = ReportType.first.class_name.constantize.new

      report.run

      expect(@controller).to receive(:send_data)
                                 .with(report.to_csv, file_options) { | _csv, _options|
                                   @controller.render body: :nil
                                 }

      get :download, params: { id: ReportType.first.id  }
    end
  end
end
