
require 'rails_helper'

describe TeamMoveService do

  describe '#call' do

    context 'moving a business unit to another directorate' do
      let(:original_dir)     { find_or_create :directorate }
      let(:bu)               { find_or_create(:business_unit, name: 'Business Unit name', directorate: original_dir) }
      let(:target_dir)       { find_or_create :directorate }

      it 'returns error when the team is not a business unit' do
        expect{
          TeamMoveService.new( original_dir, target_dir )
        }.to raise_error TeamMoveService::TeamNotBusinessUnitError,
                         "Cannot move a team which is not a business unit"

      end
      it 'returns error for the original directorate' do
        expect{
          TeamMoveService.new( bu, original_dir)
        }.to raise_error TeamMoveService::InvalidDirectorateErrror,
                         "Cannot move to the original directorate"

      end
      it 'Creates a copy of the team in the target directorate' do
        team = TeamMoveService.new( bu, target_dir)
        expect(team.new_unit.directorate).to eq target_dir
      end

      # copy of the team has associations of team_x models
      # original team must be  deactivated
      # ^^ Both to be covered in a later ticket

    end
  end
end
