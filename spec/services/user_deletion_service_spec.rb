require "rails_helper"

describe UserDeletionService do
  before do
    DbHousekeeping.clean
  end

  describe "#call" do
    let(:manager)       { find_or_create :disclosure_bmt_user }
    let(:team)          { find_or_create :foi_responding_team }
    let(:responder)     { team.responders.first }
    let(:service)       { described_class.new(params, manager) }
    let(:params) do
      {
        id: responder.id,
        team_id: team.id,
      }
    end

    context "when user is a member of one team only" do
      it "updates the deleted_at column" do
        service.call
        expect(responder.reload.deleted_at).not_to be nil
      end

      it "returns :ok" do
        service.call
        expect(service.result).to eq(:ok)
      end

      it "deletes the teams users role" do
        expect(responder.team_roles.size).to eq 1
        service.call
        expect(responder.reload.team_roles.size).to eq 0
      end
    end

    context "when user is a member of multiple teams" do
      let(:team_2) { create :responding_team }

      before do
        responder.team_roles << TeamsUsersRole.new(team: team_2, role: "responder")
        responder.save!
      end

      it "deletes the teams users role" do
        expect(responder.team_roles.size).to eq 2
        service.call
        expect(responder.reload.team_roles.size).to eq 1
        expect(responder.team_roles.last.team).to eq(team_2)
      end

      it "returns :ok" do
        service.call
        expect(service.result).to eq(:ok)
      end

      it "does not update the deleted_at column" do
        service.call
        expect(responder.reload.deleted_at).to be nil
      end
    end

    context "when user has live cases" do
      let!(:kase) do
        create :accepted_case,
               responder:,
               responding_team: team
      end

      context "and single team member" do
        it "returns :ok" do
          service.call
          expect(service.result).to eq(:ok)
        end

        it "populates the deleted_at column" do
          service.call
          expect(responder.reload.deleted_at).not_to be nil
        end

        it "unassigns the live cases from user without touching responded cases" do
          kase = create :accepted_case,
                        responder:,
                        responding_team: team

          responded_case = create :responded_case,
                                  responder:,
                                  responding_team: team,
                                  received_date: 5.days.ago

          check_key_fields_for_not_responded_case_before_deactivating_responder(kase)
          check_key_fields_for_responded_case_before_deactivating_responder(responded_case)

          service.call

          check_key_fields_for_not_responded_case_after_deactivating_responder(kase)
          check_key_fields_for_responded_case_after_deactivating_responder(responded_case)
        end

        it "sends the team an email" do
          email_service = instance_double NotifyNewAssignmentService

          allow(NotifyNewAssignmentService).to receive(:new).and_return(email_service)
          allow(email_service).to receive(:run).and_return(:ok)
          service.call
          expect(email_service).to have_received(:run)
        end
      end
    end

    context "when user is a member of one team that has incarnations" do
      let(:target_dir) { find_or_create :directorate }
      let(:team_move_service) { TeamMoveService.new(team, target_dir) }
      let(:new_team) { team_move_service.new_team }
      let(:service) { described_class.new({ id: responder.id, team_id: new_team.id }, manager) }
      let(:responder) { new_team.responders.first }

      before do
        team_move_service.call
      end

      it "updates the deleted_at column" do
        service.call
        expect(responder.reload.deleted_at).not_to be nil
      end

      it "returns :ok" do
        service.call
        expect(service.result).to eq(:ok)
      end

      it "deletes the teams users role" do
        expect(responder.team_roles.size).to eq 2
        service.call
        expect(responder.reload.team_roles.size).to eq 0
      end
    end

  private

    def check_key_fields_for_not_responded_case_before_deactivating_responder(kase)
      expect(kase.responder_assignment.state).to eq "accepted"
      expect(kase.responder).to eq responder
      expect(kase.current_state).to eq "drafting"
      expect(kase.responding_team).to eq team
    end

    def check_key_fields_for_responded_case_before_deactivating_responder(responded_case)
      expect(responded_case.responder_assignment.state).to eq "accepted"
      expect(responded_case.responder).to eq responder
      expect(responded_case.current_state).to eq "responded"
      expect(responded_case.responding_team).to eq team
    end

    def check_key_fields_for_not_responded_case_after_deactivating_responder(kase)
      kase.reload
      expect(kase.responder_assignment.state).to eq "pending"
      expect(kase.responding_team).to eq team
      expect(kase.responder).to eq nil
      expect(kase.current_state).to eq "awaiting_responder"
    end

    def check_key_fields_for_responded_case_after_deactivating_responder(responded_case)
      responded_case.reload
      expect(responded_case.responder_assignment.state).to eq "accepted"
      expect(responded_case.responder).to eq responder
      expect(responded_case.responding_team).to eq team
      expect(responded_case.current_state).to eq "responded"
    end
  end
end
