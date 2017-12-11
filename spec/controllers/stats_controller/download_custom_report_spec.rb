require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  let!(:kase)   { create :case}
  let(:manager) { create :disclosure_bmt_user }
  let!(:report) { create :report }

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')
    ReportTypeSeeder.new.seed!
  end

  describe '#download_custom_report' do
    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :download_custom_report, params: { id: report.id } }
        .to require_permission(:can_download_stats?)
              .with_args(manager, kase)
    end

    it 'responds with a csv' do
      file_options = { filename: "#{report.report_type.class_name.to_s.underscore.sub('stats/', '')}.csv",
                       disposition: :attachment }


      expect(@controller).to receive(:send_data)
                                 .with(report.report_data, file_options) { | _csv, _options|
                                   @controller.render body: :nil
                                 }

      get :download_custom_report, params: { id: report.id  }
    end
  end

end
