require 'rails_helper'

describe TeamDeletionService do

  describe '#call' do
    let(:dir)           { find_or_create :directorate }
    let(:service)       { TeamDeletionService.new(params) }
    let(:params) do
      {
        id: dir.id
      }
    end

    context 'child team is not active' do
      let(:time) { Time.new(2017, 6, 30, 12, 0, 0) }
      let!(:bu) { find_or_create(:business_unit, :deactivated, directorate: dir) }

      it 'updates the team name' do
        Timecop.freeze(time) do
          service.call
          expect(dir.reload.name).to include "DEACTIVATED", dir.name
        end
      end

      it 'updates the deleted_at column' do
        Timecop.freeze(time) do
          service.call
          expect(dir.reload.deleted_at).to eq time
        end
      end
    end

    context 'child team is active' do
      let!(:bu) { find_or_create(:business_unit, directorate: dir) }
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
