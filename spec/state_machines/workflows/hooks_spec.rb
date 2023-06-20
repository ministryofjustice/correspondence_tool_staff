require "rails_helper"

describe Workflows::Hooks do
  let(:responding_team)         { find_or_create(:foi_responding_team) }
  let(:responder)               { find_or_create(:foi_responder) }
  let(:another_responder)       do
    create :responder,
           responding_teams: [responding_team]
  end
  let(:team_disclosure)         { find_or_create :team_dacu_disclosure }
  let(:approver)                { find_or_create :disclosure_specialist }
  let(:another_approver)        do
    create :approver,
           approving_team: team_disclosure
  end
  let(:kase)                    { create(:accepted_case, :flagged_accepted) }
  let(:another_responding_team) { create :responding_team, email: "madeupemail@test.com" }
  let(:workflow)                { described_class.new(user: responder, kase:, metadata: nil) }

  describe "#notify_managing_team_case_closed" do
    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:notify_team,
                                                                :deliver_later)
    end

    it "sends a notification" do
      workflow.notify_managing_team_case_closed
      expect(ActionNotificationsMailer)
        .to have_received(:notify_team)
              .with(kase.managing_team, kase, "Case closed")
    end
  end

  describe "#reassign_user_email" do
    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:case_assigned_to_another_user,
                                                                :deliver_later)
    end

    context "when responder reassigning" do
      context "and current user is not assigning to themselves" do
        let(:workflow) { described_class.new(user: responder, kase:, metadata: { target_user: another_responder }) }

        it "sends the notification" do
          workflow.reassign_user_email
          expect(ActionNotificationsMailer)
            .to have_received(:case_assigned_to_another_user)
                  .with(kase, another_responder)
        end
      end

      context "and current_user assigns to themselves" do
        let(:workflow) { described_class.new(user: responder, kase:, metadata: { target_user: responder }) }

        it "does not send the notification" do
          workflow.reassign_user_email
          expect(ActionNotificationsMailer)
            .not_to have_received(:case_assigned_to_another_user)
                  .with(kase, another_responder)
        end
      end
    end

    context "when approver reassigning" do
      context "and current user is not assigning to themselves" do
        let(:workflow) { described_class.new(user: responder, kase:, metadata: { target_user: another_approver }) }

        it "sends the notification" do
          workflow.reassign_user_email
          expect(ActionNotificationsMailer)
            .to have_received(:case_assigned_to_another_user)
                  .with(kase, another_approver)
        end
      end
    end
  end

  describe "#assign_responder_email" do
    let(:workflow) { described_class.new(user: responder, kase:, metadata: { target_team: another_responding_team }) }

    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:new_assignment,
                                                                :deliver_later)
    end

    context "when responder reassigning" do
      context "and team has email adress" do
        it "sends a notification" do
          workflow.assign_responder_email
          expect(ActionNotificationsMailer)
            .to have_received(:new_assignment)
                  .with(kase.responder_assignment, another_responding_team.email)
        end
      end
    end
  end

  describe "#notify_approver_ready_for_review" do
    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:ready_for_press_or_private_review,
                                                                :deliver_later)
    end

    it "sends the notification" do
      workflow.notify_approver_ready_for_review
      expect(ActionNotificationsMailer)
        .to have_received(:ready_for_press_or_private_review)
    end
  end
end
