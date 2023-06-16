require "rails_helper"

describe CaseAssignToTeamMemberService, type: :service do
  let(:team) { find_or_create :team_branston }
  let(:unassigned_case) { find_or_create :offender_sar_complaint }
  let(:responder) { find_or_create :branston_user }
  let(:service) do
    described_class
                              .new kase: unassigned_case,
                                   role: "responding",
                                   user: responder
  end
  let(:new_assignment) { instance_double Assignment }

  describe "#initialize" do
    it "defaults result to incomplete" do
      expect(service.result).to eq :incomplete
    end
  end

  describe "#call" do
    before do
      allow(unassigned_case).to receive_message_chain(:assignments,
                                                      new: new_assignment)
      allow(unassigned_case.state_machine).to receive(:assign_responder!)
      allow(unassigned_case.state_machine).to receive(:accept_approver_assignment!)
    end

    context "assignment is valid" do
      before do
        allow(new_assignment).to receive_messages valid?: true,
                                                  save!: true,
                                                  case: unassigned_case,
                                                  user: responder,
                                                  team:,
                                                  accepted!: true,
                                                  state: "accepted"
      end

      it "returns true on success" do
        expect(service.call).to eq true
      end

      it "sets the result to :ok" do
        service.call
        expect(service.result).to eq :ok
      end

      it "triggers an assign_to_team_member! event" do
        expect(unassigned_case.state_machine)
            .to receive(:assign_to_team_member!)
                    .with(
                      acting_user: responder,
                      acting_team: responder.responding_teams.first,
                      target_team: team,
                      target_user: responder,
                    )
        service.call
      end

      it "saves the assignment" do
        service.call
        expect(service.assignment).to eq new_assignment
      end

      it "assignment is accepted" do
        service.call
        expect(service.assignment.state).to eq "accepted"
      end
    end
  end
end
