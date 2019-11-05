
require 'rails_helper'

describe TeamMoveService do

  describe '#call' do

    context 'moving a business unit to another directorate' do
      let(:original_dir)     { find_or_create :directorate }
      let(:bu) { find_or_create(:business_unit, directorate: original_dir) }

      # let(:team_move) { TeamteamService.new(:bu, :target_dir) }
      it 'returns error for the original directorate' do
        expect{
          TeamMoveService.new( bu, original_dir)
        }.to raise_error TeamMoveService::InvalidDirectorate,
                         "Cannot move to the original directorate"

      end

    end
  end
end
