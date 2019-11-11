
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
      it 'returns error when the target directorate is not a directorate' do
        expect{
          TeamMoveService.new( bu, bu )
        }.to raise_error TeamMoveService::InvalidDirectorateError,
                         "Cannot move a Business Unit to a team that is not a directorate"

      end
      it 'returns error for the original directorate' do
        expect{
          TeamMoveService.new( bu, original_dir)
        }.to raise_error TeamMoveService::OriginalDirectorateError,
                         "Cannot move to the original directorate"

      end
      it 'Creates a copy of the team in the target directorate' do
        team = TeamMoveService.new( bu, target_dir)
        expect(team.new_unit.directorate).to eq target_dir
      end
      it 'Moves team user_roles to the new team, and removes them from the original team' do

        tur = TeamsUsersRole.create user: create(:user),
                                    team: bu,
                                    role: 'manager'

        team = TeamMoveService.new( bu, target_dir)
        expect(team.new_unit.user_roles.first).to eq tur
        expect(bu.user_roles.first).to eq nil
      end

      # original team must be  deactivated
      # ^^ Both to be covered in a later ticket

    end
  end
end
