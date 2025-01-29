require "rails_helper"

describe DataRequestChaseService do
  let(:in_progress) { create(:data_request_area, :in_progress) }
  let(:current_user) { in_progress.kase.creator }
  let(:service) { CommissioningDocumentEmailService }

  before do
    in_progress.commissioning_document.update(sent_at: Date.current)
    allow(CommissioningDocumentEmailService).to receive(:new).with(
      data_request_area: in_progress, commissioning_document: in_progress.commissioning_document, current_user:,
    ).and_return(service)
  end

  describe "#call" do
    context "when chase is due" do
      it "sends request to email service" do
        allow_any_instance_of(DataRequestArea).to receive(:next_chase_date).and_return(Date.current) # rubocop:disable RSpec/AnyInstance

        expect(service).to receive(:send_chase!)
        described_class.call
      end
    end

    context "when chase is not due" do
      it "does not send request to email service" do
        allow_any_instance_of(DataRequestArea).to receive(:next_chase_date).and_return(Date.current + 1.day) # rubocop:disable RSpec/AnyInstance

        expect(service).to_not receive(:send_chase!)
        described_class.call
      end
    end
  end
end
