require "rails_helper"

RSpec.describe MailDeliveryObserver, type: :observer do
  let(:data_request_email) { create(:data_request_email) }
  let(:notify_id) { "35daaa7a-2859-4c39-a5f2-bfdb17a053f4" }
  let(:message) do
    OpenStruct.new(
      header: { "dreid" => OpenStruct.new(value: data_request_email.id) },
      govuk_notify_response: OpenStruct.new(id: notify_id),
    )
  end

  describe ".delivered_email" do
    it "updates the record with the notify ID" do
      described_class.delivered_email(message)
      expect(data_request_email.reload.notify_id).to eq notify_id
    end
  end
end
