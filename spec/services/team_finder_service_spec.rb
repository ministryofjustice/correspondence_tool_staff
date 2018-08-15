require 'rails_helper'


describe TeamFinderService do

  # teams
  let(:team_bmt)                    { find_or_create :team_disclosure_bmt }
  let(:team_disclosure)             { find_or_create :team_disclosure }
  let(:team_candi)                  { create :responding_team, name: 'Candi' }

  # users
  let(:responder)                   { create :responder, responding_teams: [team_candi] }
  let(:other_reponder)              { create :responder, responding_teams: [team_candi] }
  let(:multi_role_user) do
    create :user,
           managing_teams: [team_bmt],
           approving_team: team_disclosure,
           responding_teams: [team_candi]
  end

  let(:other_approver)              { create :user, approving_team: team_disclosure }

  #cases
  let(:kase) do
    create :case_with_response, :flagged_accepted,
           responder: responder,
           approving_team: team_disclosure,
           approver: multi_role_user
  end

  let(:other_responder_case)        { create :case_with_response, responder: other_reponder }


  context 'user assignment with correct role exists' do
    it 'returns the correct team' do
      team = TeamFinderService.new(kase, responder, :responder).call
      expect(team).to eq team_candi
    end
  end

  context 'kase was assigned to responder in the same team' do
    it 'returns the responding team' do
      team = TeamFinderService.new(other_responder_case, responder, :responder).call
      expect(team).to eq team_candi
    end
  end

  context 'user has all three roles' do
    context 'find responding team' do
      it 'returns the responding team' do
        team = TeamFinderService.new(kase, multi_role_user, :responder).call
        expect(team).to eq team_candi
      end
    end

    context 'find managing team' do
      it 'returns the managing team' do
        team = TeamFinderService.new(kase, multi_role_user, :manager).call
        expect(team).to eq team_bmt
      end
    end

    context 'find approving team' do
      context 'with the assigned approver' do
        it 'returns the approving team' do
          team = TeamFinderService.new(kase, multi_role_user, :approver).call
          expect(team).to eq team_disclosure
        end
      end

      context 'with another approver in the same team' do
        it 'returns the approving team' do
          team = TeamFinderService.new(kase, other_approver, :approver).call
          expect(team).to eq team_disclosure
        end
      end
    end
  end


  context 'Invalid team role' do
    it 'raises' do
      expect {
        TeamFinderService.new('mock_case', 'mock_user', :assessor)
      }.to raise_error ArgumentError, 'Invalid role'
    end
  end


end
