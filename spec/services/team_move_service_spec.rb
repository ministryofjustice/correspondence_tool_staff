require 'rails_helper'

describe TeamMoveService do
  let(:original_dir) { find_or_create :directorate }
  let(:target_dir) { find_or_create :directorate }
  let(:responder) { create(:foi_responder, responding_teams: [business_unit]) }
  let(:service) { TeamMoveService.new(business_unit, target_dir) }
  let(:business_unit) {
    find_or_create(
      :business_unit,
        name: 'Business Unit name',
        directorate: original_dir,
        code: 'ABC'
    )
  }
  let!(:kase) {
    create(
      :case_being_drafted,
        responding_team: business_unit,
        responder: responder
    )
  }
  let!(:klosed_kase) {
    create(
      :closed_case,
        responding_team: business_unit,
        responder: responder
    )
  }


  describe '#initialize' do
    it 'returns error when the team is not a business unit' do
      expect{
        TeamMoveService.new(original_dir, target_dir)
      }.to raise_error TeamMoveService::TeamNotBusinessUnitError,
                       "Cannot move a team which is not a Business Unit"
    end

    it 'returns error when the target directorate is not a directorate' do
      expect{
        TeamMoveService.new(business_unit, business_unit)
      }.to raise_error TeamMoveService::InvalidDirectorateError,
                       "Cannot move a Business Unit to a team that is not a Directorate"
    end

    it 'returns error for the original directorate' do
      expect{
        TeamMoveService.new(business_unit, original_dir)
      }.to raise_error TeamMoveService::OriginalDirectorateError,
                       "Cannot move to the original Directorate"
    end

    it 'requires a business unit and a target directorate' do
      expect(service.instance_variable_get(:@team)).to eq business_unit
      expect(service.instance_variable_get(:@directorate)).to eq target_dir
      expect(service.instance_variable_get(:@result)).to eq :incomplete
    end
  end

  describe '#call' do
    context 'moving a business unit to another directorate' do
      it 'creates a copy of the team in the target directorate' do
        service.call

        expect(service.new_team.directorate).to eq target_dir
      end

      it 'moves team users to the new team, and removes them from the original team' do
        expect(business_unit.users).to match_array [responder]
        service.call

        expect(business_unit.users).to match_array []
        expect(service.new_team.users).to match_array [responder]
      end

      it 'moves team user_roles to the new team, and removes them from the original team' do
        team_user_role = business_unit.user_roles.first
        service.call

        expect(service.new_team.user_roles.first).to eq team_user_role
        expect(business_unit.reload.user_roles).to be_empty
      end

      context 'when the team being moved has open cases' do
        it 'moves open cases to the new team and removes them from the original team' do
          expect(business_unit.open_cases.first).to eq kase
          service.call

          expect(business_unit.open_cases).to be_empty
          expect(service.new_team.open_cases.first).to eq kase
        end

        it 'moves all transitions of the open case to the new team' do
          service.call

          # using factory :case_being_drafted, the case has TWO transitions,
          # One for the transition to drafted,
          # and one for the current _being drafted_ state (in the second, the target team is nill)
          expect(kase.transitions.first.target_team_id).to eq service.new_team.id
          expect(kase.transitions.second.acting_team_id).to eq service.new_team.id
        end
      end

      context 'when the team being moved has closed cases' do
        it 'leaves closed cases with the original team' do
          expect(business_unit.cases.closed.first).to eq klosed_kase
          service.call

          expect(service.new_team.cases.closed).to be_empty
          expect(business_unit.cases.closed.first).to eq klosed_kase
        end
      end

      it 'sets old team to deleted' do
        service.call

        expect(business_unit.reload.deleted_at).not_to be_nil
      end

      it 'sets new team to moved and showing the original team name' do
        service.call

        expect(service.new_team).to eq business_unit.moved_to_unit
        expect(service.new_team.name).to eq business_unit.original_team_name
      end
    end
  end
end
