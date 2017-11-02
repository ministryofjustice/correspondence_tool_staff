require 'rails_helper'

describe TeamDeletionService do

  describe '#call' do
    let(:team)          { create :responding_team }
    let(:responder)     { team.responders.first }
    let(:service)       { TeamDeletionService.new(params) }
    let(:params) do
      {
        id: team.id
      }
    end

    it 'updates the team name' do
      service.call
      expect(team.reload.name).to include "DEACTIVATED", team.name
    end
    
    it 'updates the deleted_at column' do
      expect(team.reload.deleted_at).to be nil
      service.call
      expect(team.reload.deleted_at).not_to be nil
    end
  end
end
