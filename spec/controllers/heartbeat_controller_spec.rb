require 'rails_helper'

RSpec.describe HeartbeatController, type: :controller do

  describe '#ping' do
    describe 'does not force ssl' do
      before do
        allow(Rails).to receive(:env).and_return(double(development?: false, production?: true))
      end

      it 'ping the endpoint' do
        get :ping
        expect(response.status).not_to eq(301)
      end

    end

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
end
