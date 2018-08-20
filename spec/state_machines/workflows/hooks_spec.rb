require "rails_helper"

describe Workflows::Hooks do
  let(:user)     { create(:responder) }
  let(:kase)     { create(:foi_case)  }
  let(:workflow) { described_class.new(user: user, kase: kase) }

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
end
