require "rails_helper"

describe Workflows::Hooks do
  let(:responder)               { create(:responder, responding_teams: [responding_team]) }
  let(:another_responder)       { create :responder, responding_teams: [responding_team] }
  let(:approver)                { create :disclosure_specialist}
  let(:another_approver)        { create :disclosure_specialist}
  let(:kase)                    { create(:accepted_case, :flagged_accepted, :dacu_disclosure, approver: approver, responder: responder)  }
  let(:responding_team)         { find_or_create(:responding_team) }
  let(:another_responding_team) { create :responding_team, email: 'madeupemail@test.com'}
  let(:workflow)                { described_class.new(user: responder, kase: kase, metadata: nil) }

  describe '#notify_managing_team_case_closed' do
    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:notify_team,
                                                                :deliver_later)
    end

    it 'sends a notification' do
      workflow.notify_managing_team_case_closed
      expect(ActionNotificationsMailer)
        .to have_received(:notify_team)
              .with(kase.managing_team, kase, 'Case closed')
    end
  end

  describe '#reassign_user_email' do
    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:case_assigned_to_another_user,
                                                                :deliver_later)
    end
    context 'responder reassigning' do
      context 'current user is not assigning to themselves' do
        let(:workflow) { described_class.new(user: responder, kase: kase, metadata: {target_user: another_responder}) }

        it 'sends the notification' do
          workflow.reassign_user_email
          expect(ActionNotificationsMailer)
            .to have_received(:case_assigned_to_another_user)
                  .with(kase, another_responder)
        end
      end

      context 'current_user assigns to themselves' do
        let(:workflow) { described_class.new(user: responder, kase: kase, metadata: {target_user: responder}) }

        it 'does not send the notification' do
          workflow.reassign_user_email
          expect(ActionNotificationsMailer)
            .not_to have_received(:case_assigned_to_another_user)
                  .with(kase, another_responder)
        end
      end
    end

    context 'approver reassigning' do
      context 'current user is not assigning to themselves' do
        let(:workflow) { described_class.new(user: responder, kase: kase, metadata: {target_user: another_approver}) }

        it 'sends the notification' do
          workflow.reassign_user_email
          expect(ActionNotificationsMailer)
            .to have_received(:case_assigned_to_another_user)
                  .with(kase, another_approver)
        end
      end
    end
  end

  describe '#assign_responder_email' do
    let(:workflow)    { described_class.new(user: responder, kase: kase, metadata: {target_team: another_responding_team}) }

    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:new_assignment,
                                                                :deliver_later)
    end

    context 'responder reassigning' do
      context 'team has email adress' do
        it 'sends a notification' do
          workflow.assign_responder_email
          expect(ActionNotificationsMailer)
            .to have_received(:new_assignment)
                  .with(kase.responder_assignment, another_responding_team.email)
        end
      end
    end
  end
end
