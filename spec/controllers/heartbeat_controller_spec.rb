require 'rails_helper'

RSpec.describe HeartbeatController, type: :controller do

  describe '#ping' do
    it 'returns JSON with app information' do
      get :ping

      ping_response = JSON.parse response.body
      # Settings can be nil, and since we don't test Settings anywhere else we do it here.
      expect(ping_response['build_date']).not_to be_nil
      expect(ping_response['build_date']).to eq Settings.build_date
      expect(ping_response['git_commit']).not_to be_nil
      expect(ping_response['git_commit']).to eq Settings.git_commit
      expect(ping_response['git_source']).not_to be_nil
      expect(ping_response['git_source']).to eq Settings.git_source
    end
  end

  describe '#healthcheck' do

    context 'when a problem exists' do
      before do
        allow(ActiveRecord::Base.connection)
            .to receive(:active?).and_raise(PG::ConnectionBad)

        get :healthcheck
      end

      it 'returns status bad gateway' do
        expect(response.status).to eq(502)
      end

      it 'returns the expected response report' do
        expect(response.body).to eq({checks: { database: false}}.to_json)
      end
    end

    context 'when everything is ok' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)

        get :healthcheck
      end

      it 'returns HTTP success' do
        expect(response.status).to eq(200)
      end

      it 'returns the expected response report' do
        expect(response.body).to eq({checks: { database: true}}.to_json)
      end
    end
  end
end
