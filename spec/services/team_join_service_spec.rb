require 'rails_helper'

describe TeamJoinService do
  let(:original_dir) { find_or_create :directorate }
  let(:target_dir) { find_or_create :directorate }
  let(:responder) { create(:foi_responder, responding_teams: [business_unit]) }
  let(:service) { TeamJoinService.new(business_unit, target_business_unit) }
  let(:business_unit) {
    find_or_create(
      :business_unit,
      name: 'Business Unit name',
      directorate: original_dir,
      code: 'ABC'
    )
  }
  let(:target_business_unit) {
    find_or_create(
      :business_unit,
      name: 'Target Business Unit name',
      directorate: target_dir,
      code: 'XYZ'
    )
  }

  let(:params) do
    HashWithIndifferentAccess.new(
        {
            'full_name' => 'Bob Dunnit',
            'email' => 'bd@moj.com'
        }
    )
  end

  let(:team_move_service) { TeamMoveService.new(business_unit, target_dir) }
  let(:second_user_service) { UserCreationService.new(team: business_unit, params: params)}

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
        TeamJoinService.new(original_dir, target_business_unit)
      }.to raise_error TeamJoinService::TeamNotBusinessUnitError,
                       "Cannot move a team which is not a Business Unit"
    end

    it 'returns error when the target team is not a team' do
      expect{
        TeamJoinService.new(business_unit, original_dir)
      }.to raise_error TeamJoinService::InvalidTargetBusinessUnitError,
                       "Cannot join a Business Unit to a team that is not a Business Unit"
    end

    it 'returns error for the original team' do
      expect{
        TeamJoinService.new(business_unit, business_unit)
      }.to raise_error TeamJoinService::OriginalBusinessUnitError,
                       "Cannot join a Business Unit to itself"
    end

    it 'requires a business unit and a target business unit' do
      expect(service.instance_variable_get(:@team)).to eq business_unit
      expect(service.instance_variable_get(:@target_team)).to eq target_business_unit
      expect(service.instance_variable_get(:@result)).to eq :incomplete
    end
  end

  describe '#call' do
    context 'joining a business unit into another business unit' do
      it 'Joins team users to the new team' do

        expect(business_unit.users).to match_array [responder]
        service.call

        expect(service.target_team.users).to match_array [responder]
      end

      it 'Joins team user_roles to the new team, and does not remove them from the original team' do
        second_user_service.call
        retained_user_roles = business_unit.user_roles.as_json.map {|ur| [ur["team_id"], ur["user_id"], ur["role"]]}
        service.call
        new_user_roles = business_unit.reload.user_roles.as_json.map {|ur| [ur["team_id"], ur["user_id"], ur["role"]]}
        expect(new_user_roles).to include retained_user_roles[0]
        expect(new_user_roles).to include retained_user_roles[1]
      end
      it 'gives users from old team roles on all the history of the new team' do
        #TODO - first do the team.historic_user_roles code, and test in Business_Unit
      #   # make a team get the roles
      #   retained_user_roles = business_unit.user_roles.as_json.map {|ur| [ur["team_id"], ur["user_id"], ur["role"]]}
      #   # move the team (making history)
      #   team_move_service.call
      #   # make a second team & join the second team to the first team
      #   service.call
      #   target_user_roles = target_business_unit.reload.user_roles.as_json.map {|ur| [ur["team_id"], ur["user_id"], ur["role"]]}
      #   # check that second team users have role on first teams deactivated self
      #   expect(target_user_roles).to include [retained_user_roles[0][0], target_business_unit.users.first.id, retained_user_roles[0][2]]
      end
      it 'allows new team users to see team history of the old team' do
        #TODO
      end
      it 'sets old team to deleted' do
        service.call

        expect(business_unit.reload.deleted_at).not_to be_nil
      end

      it 'sets moved to on old team' do
        service.call
        expect(service.target_team).to eq business_unit.moved_to_unit
      end

      context 'when the team being moved has open cases' do
        it 'Joins open cases to the new team and removes them from the original team' do
          expect(business_unit.open_cases.first).to eq kase
          service.call

          expect(business_unit.open_cases).to be_empty
          expect(service.target_team.open_cases.first).to eq kase
        end

        it 'Joins all transitions of the open case to the new team' do
          service.call

          # using factory :case_being_drafted, the case has TWO transitions,
          # One for the transition to drafted,
          # and one for the current _being drafted_ state (in the second, the target team is nill)
          expect(kase.transitions.first.target_team_id).to eq service.target_team.id
          expect(kase.transitions.second.acting_team_id).to eq service.target_team.id
        end
      end

      context 'when the team being moved has closed cases' do
        it 'leaves closed cases with the original team' do
          expect(business_unit.cases.closed.first).to eq klosed_kase
          service.call

          expect(service.target_team.cases.closed).to be_empty
          expect(business_unit.cases.closed.first).to eq klosed_kase
        end
      end

      context 'when the team being moved has trigger cases' do
        let(:kase) {
          create(
            :case_being_drafted, :flagged,
            responding_team: business_unit,
            responder: responder
          )
        }
        it 'leaves the approving teams as Disclosure' do
          expect(kase.approving_teams).to eq [BusinessUnit.dacu_disclosure]
          service.call

          expect(kase.reload.approving_teams).to eq [BusinessUnit.dacu_disclosure]
        end
      end
    end
  end
end
