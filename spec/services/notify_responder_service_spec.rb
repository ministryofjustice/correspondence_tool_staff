require "rails_helper"

describe NotifyResponderService, type: :service do
  let(:responded_case) { create :responded_case }
  let(:service)        { described_class.new(responded_case, "mail_type") }

  before do
    allow(ActionNotificationsMailer).to receive(:notify_information_officers).and_call_original
  end

  it "sets the result to ok" do
    service.call
    expect(service.result).to eq :ok
  end

  it "emails" do
    service.call
    expect(ActionNotificationsMailer).to have_received(:notify_information_officers)
  end
end
