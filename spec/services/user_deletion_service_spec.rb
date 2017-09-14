require 'rails_helper'

describe UserDeletionService do

  describe '#call' do

    let(:team)          { create :responding_team }
    let(:responder)     { team.responders.first }
    let(:service)       { UserDeletionService.new(params) }
    let(:params) do
      {
        id: responder.id,
        team_id: team.id
      }
    end

    context 'user is a member of one team only' do
      context 'when user has no live cases' do
        it 'updates the deleted_at column' do
          service.call
          expect(responder.reload.deleted_at).not_to be nil
        end

        it 'returns :ok' do
          service.call
          expect(service.result).to eq(:ok)
        end
      end

      context 'when user has live cases' do
        let!(:kase)        { create :accepted_case, responder: responder }

        it 'returns :has_live_cases' do
          service.call
          expect(service.result).to eq(:has_live_cases)
        end
      end
    end

    context 'when user is a member of multiple teams' do

      let(:team_2) { create :responding_team}

      before(:each) do
        responder.team_roles << TeamsUsersRole.new(team: team_2, role: 'responder')
        responder.save!
      end

      it 'deletes the teams users role' do
        expect(responder.team_roles.size).to eq 2
        service.call
        expect(responder.team_roles.size).to eq 1
        expect(responder.team_roles.last.team).to eq(team_2)
      end

      it 'returns :ok' do
        service.call
        expect(service.result).to eq(:ok)
      end
    end
  end
end
