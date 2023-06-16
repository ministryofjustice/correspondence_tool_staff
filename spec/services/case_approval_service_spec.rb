require "rails_helper"

describe CaseApprovalService do
  describe "#call" do
    context "not bypassing press private approval" do
      let(:bypass_params) do
        double BypassParamsManager,
               valid?: true,
               approval_requested?: true,
               present?: false
      end
      let(:service) { described_class.new(user:, kase:, bypass_params:) }

      before do
        allow(ActionNotificationsMailer).to receive_message_chain(:ready_for_press_or_private_review,
                                                                  :deliver_later)
      end

      context "case not in pending_dacu_clearance state" do
        let(:kase) { create :redrafting_case, :flagged_accepted }
        let(:user) { kase.approvers.first }

        it "raises state machine guard error" do
          expect(kase.current_state).to eq "drafting"
          service.call
          expect(service.result).to eq :error
        end
      end

      context "approving case with valid state and user" do
        let(:kase) { create :pending_dacu_clearance_case }
        let(:user) { kase.approvers.first }

        it "returns :ok" do
          service.call
          expect(service.result).to eq :ok
        end

        it "sets the assignment approved flag" do
          expect(kase.approver_assignments.first.approved?).to be false
          service.call
          expect(kase.approver_assignments.first.approved?).to be true
        end

        it "sets the state to awaiting_dispatch" do
          expect(kase.current_state).to eq "pending_dacu_clearance"
          service.call
          expect(kase.current_state).to eq "awaiting_dispatch"
        end

        it "adds a case_transition record" do
          expect {
            service.call
          }.to change { kase.transitions.size }.by(1)
          transition = kase.transitions.last
          expect(transition.event).to eq "approve"
          expect(transition.acting_user_id).to eq user.id
          expect(transition.acting_team_id).to eq kase.approving_teams.first.id
        end

        it "does not send an email" do
          service.call
          expect(ActionNotificationsMailer).not_to have_received(:ready_for_press_or_private_review)
        end
      end

      context "approving case that requires another level of clearance" do
        let(:kase)            { create :pending_dacu_clearance_case_flagged_for_press }
        let(:user)            { kase.assigned_disclosure_specialist! }
        let(:dacu_disclosure) { find_or_create :team_dacu_disclosure }

        it "returns :ok" do
          service.call
          expect(service.result).to eq :ok
        end

        it "sets the assignment approved flag" do
          expect(kase.approver_assignments.with_teams(dacu_disclosure).first.approved?).to be false
          service.call
          expect(kase.approver_assignments.with_teams(dacu_disclosure).first.approved?).to be true
        end

        it "sets the state to awaiting_dispatch" do
          expect(kase.current_state).to eq "pending_dacu_clearance"
          service.call
          expect(kase.current_state).to eq "pending_press_office_clearance"
        end

        it "adds a case_transition record" do
          expect {
            service.call
          }.to change { kase.transitions.size }.by(1)
          transition = kase.transitions.last
          expect(transition.event).to eq "approve"
          expect(transition.acting_user_id).to eq user.id
          expect(transition.acting_team_id).to eq dacu_disclosure.id
        end

        it "does send an email" do
          assignment = kase.approver_assignments.with_teams(BusinessUnit.press_office).first
          service.call
          expect(ActionNotificationsMailer).to have_received(:ready_for_press_or_private_review).with assignment
        end
      end

      context "approving case with different user in the same team" do
        let(:kase) { create :pending_dacu_clearance_case }
        let(:user) do
          create :approver,
                 approving_team: kase.approving_teams.first
        end

        it "returns :error" do
          service.call
          expect(service.result).to eq :error
        end

        it "does not send an email" do
          service.call
          expect(ActionNotificationsMailer).not_to have_received(:ready_for_press_or_private_review)
        end
      end
    end

    context "bypassing press and private approval" do
      let(:bypass_params) do
        double BypassParamsManager,
               valid?: true,
               approval_requested?: false,
               bypass_requested?: true,
               message: "This is the reason for bypassing press approval",
               present?: true
      end
      let(:service) { described_class.new(user:, kase:, bypass_params:) }
      let(:user) { kase.approvers.first }

      context "case not in pending_dacu_clearance state" do
        let(:kase) { create :redrafting_case, :flagged_accepted }

        it "raises state machine guard error" do
          expect(kase.current_state).to eq "drafting"
          service.call
          expect(service.result).to eq :error
        end
      end

      context "case in pending_dacu_clearance_state flagged for press" do
        context "case not flagged for press clearance" do
          let(:kase)  { create :pending_dacu_clearance_case_flagged_for_press }

          it "transitions to awaiting dispatch" do
            service.call
            expect(kase.reload.current_state).to eq "awaiting_dispatch"
          end

          it "returns result ok" do
            service.call
            expect(service.result).to eq :ok
          end
        end
      end
    end
  end
end
