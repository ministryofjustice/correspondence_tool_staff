require 'rails_helper'

describe UserDeletionService do

  describe '#call' do

    let(:team)          { find_or_create :foi_responding_team }
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

        it 'deletes the teams users role' do
          expect(responder.team_roles.size).to eq 1
          service.call
          expect(responder.team_roles.size).to eq 0
        end
      end

      context 'when user has live cases' do
        let!(:kase)        { create :accepted_case,
                                    responder: responder,
                                    responding_team: team }

        it 'returns :has_live_cases' do
          service.call
          expect(service.result).to eq(:ok)
        end

        it 'updates the deleted_at column' do
          service.call
          expect(responder.reload.deleted_at).not_to be nil
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

      it 'does not update the deleted_at column' do
        service.call
        expect(responder.reload.deleted_at).to be nil
      end

      context 'where one team has live cases and the other does not' do
        let!(:kase) { create :accepted_case,
                             responding_team: team_2,
                             responder: responder  }

        it 'returns :ok' do
          service.call
          expect(service.result).to eq(:ok)
        end

        it 'deletes the teams users role' do
          expect(responder.team_roles.size).to eq 2
          service.call
          expect(responder.team_roles.size).to eq 1
          expect(responder.team_roles.last.team).to eq(team_2)
        end

      end
    end
  end
end
