require "rails_helper"

describe CaseAssignResponderService, type: :service do
  let(:manager)           { create :manager }
  let(:unassigned_case)   { create :case }
  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:service)           do
    described_class
                              .new team: responding_team,
                                   kase: unassigned_case,
                                   role: "responding",
                                   user: manager
  end
  let(:new_assignment) { instance_double Assignment }

  describe "#call" do
    before do
      allow(unassigned_case).to receive_message_chain(:assignments,
                                                      new: new_assignment)
      allow(unassigned_case.state_machine).to receive(:assign_responder!)
      allow(ActionNotificationsMailer).to receive_message_chain(:new_assignment,
                                                                :deliver_later)
    end

    context "assignment is valid" do
      before do
        allow(new_assignment).to receive_messages valid?: true,
                                                  save: true
      end

      it "returns true on success" do
        expect(service.call).to eq true
      end

      it "sets the result to :ok" do
        service.call
        expect(service.result).to eq :ok
      end

      it "triggers an assign_responder! event" do
        expect(unassigned_case.state_machine)
            .to receive(:assign_responder!)
                    .with(
                      acting_user: manager,
                      acting_team: manager.managing_teams.first,
                      target_team: responding_team,
                    )
        service.call
      end

      it "saves the assignment" do
        service.call
        expect(service.assignment).to eq new_assignment
      end
    end

    context "created assignment is invalid" do
      before do
        allow(new_assignment).to receive_messages valid?: false,
                                                  save: false
      end

      it "sets the result" do
        service.call
        expect(service.result).to eq :could_not_create_assignment
      end

      it "returns false" do
        expect(service.call).to eq false
      end
    end
  end
end
