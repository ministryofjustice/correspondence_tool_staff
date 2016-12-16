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
end
