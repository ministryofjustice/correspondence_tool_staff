require 'rails_helper'

describe TeamMoveService do
  describe '#call' do
    context 'moving a business unit to another directorate' do
      let(:original_dir)     { find_or_create :directorate }
      let(:bu)               { find_or_create(:business_unit, name: 'Business Unit name', directorate: original_dir) }
      let(:target_dir)       { find_or_create :directorate }

      it 'returns error when the team is not a business unit' do
        expect{
          TeamMoveService.new(original_dir, target_dir)
        }.to raise_error TeamMoveService::TeamNotBusinessUnitError,
                         "Cannot move a team which is not a Business Unit"
      end

      it 'returns error when the target directorate is not a directorate' do
        expect{
          TeamMoveService.new( bu, bu )
        }.to raise_error TeamMoveService::InvalidDirectorateError,
                         "Cannot move a Business Unit to a team that is not a Directorate"
      end

      it 'returns error for the original directorate' do
        expect{
          TeamMoveService.new( bu, original_dir)
        }.to raise_error TeamMoveService::OriginalDirectorateError,
                         "Cannot move to the original Directorate"
      end

      it 'Creates a copy of the team in the target directorate' do
        @service = TeamMoveService.new( bu, target_dir)
        @service.call
        expect(@service.new_team.directorate).to eq target_dir
      end

      it 'moves team user_roles to the new team, and removes them from the original team' do
        team_user_role = TeamsUsersRole.create(
          user: create(:user),
          team: bu,
          role: 'manager'
        )
        @service = TeamMoveService.new( bu, target_dir)
        @service.call
        expect(@service.new_team.user_roles.first).to eq team_user_role
        expect(bu.user_roles.first).to eq nil
      end

      # TODO: original team must be deactivated, to be covered in a later ticket
    end
  end
end
