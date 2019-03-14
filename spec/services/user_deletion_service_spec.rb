require 'rails_helper'

describe UserDeletionService do

  describe '#call' do

    let(:manager)       { find_or_create :disclosure_bmt_user}
    let(:team)          { find_or_create :foi_responding_team }
    let(:responder)     { team.responders.first }
    let(:service)       { UserDeletionService.new(params, manager) }
    let(:params) do
      {
        id: responder.id,
        team_id: team.id
      }
    end

    context 'user is a member of one team only' do
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
        expect(responder.reload.team_roles.size).to eq 0
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
        expect(responder.reload.team_roles.size).to eq 1
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
    end

    context 'when user has live cases' do
      let!(:kase)        { create :accepted_case,
                                  responder: responder,
                                  responding_team: team }
      context 'single team member' do
        it 'returns :ok' do
          service.call
          expect(service.result).to eq(:ok)
        end

        it 'populates the deleted_at column' do
          service.call
          expect(responder.reload.deleted_at).not_to be nil
        end

        it 'unassigns the cases from user' do
          kase = create :accepted_case,
                        responder: responder,
                        responding_team: team
          expect(kase.responder).to eq responder
          service.call
          # expect(kase.responder_assignment.user_id).to eq nil
          expect(kase.responding_team).to eq team
        end

        it 'sends the team an email' do
          email_service = instance_double NotifyNewAssignmentService

          allow(NotifyNewAssignmentService).to receive(:new).and_return(email_service)
          allow(email_service).to receive(:run).and_return(:ok)
          service.call
          expect(email_service).to have_received(:run)
        end
      end
    end
  end
end
