require 'rails_helper'

describe TeamDeletionService do

  describe '#call' do
    let(:dir)           { create :dacu_directorate }
    let(:service)       { TeamDeletionService.new(params) }
    let(:params) do
      {
        id: dir.id
      }
    end
    context 'child team is not active' do
      let!(:bu) { create(:deactivated_team,
                          directorate: dir) }
      it 'updates the team name' do
        service.call
        expect(dir.reload.name).to include "DEACTIVATED", dir.name
      end

      it 'updates the deleted_at column' do
        service.call
        expect(dir.reload.deleted_at).not_to be nil
      end
    end

    context 'child team is active' do
      let!(:bu) { create(:team_dacu,
                          directorate: dir) }
      it 'does not change the name' do
        service.call
        expect(dir.reload.name).not_to include "DEACTIVATED"
      end
      it 'does not update the deleted_at column' do
        service.call
        expect(dir.reload.deleted_at).to be nil
      end
    end
  end
end
