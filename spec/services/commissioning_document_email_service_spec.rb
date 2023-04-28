require 'rails_helper'

describe CommissioningDocumentEmailService do
  let(:responder) { find_or_create :sar_responder }
  let(:kase) { create(:offender_sar_case, responder: responder) }
  let(:contact) { create(:contact) }
  let(:data_request) { create(:data_request, offender_sar_case: kase, contact: contact) }
  let(:commissioning_document) { create(:commissioning_document, ) }
  let(:user) { kase.responder }
  let(:attachment) { create(:commissioning_document_attachment) }
  let(:uploader) { instance_double(S3Uploader, upload_file_to_case: attachment) }
  let(:service) do
    CommissioningDocumentEmailService.new(
      data_request: data_request,
      current_user: responder,
      commissioning_document: commissioning_document,
    )
  end

  before do
    allow(S3Uploader).to receive(:new).and_return(uploader)
  end

  after(:all) { DbHousekeeping.clean(seed: true) }

  describe '#send!' do
    it 'sets commissioning document as sent' do
      service.send!
      expect(commissioning_document.sent).to be_truthy
    end

    it 'adds a case history entry' do
      service.send!
      transistion = kase.transitions.last
      expect(transistion.event).to eq "send_day_1_email"
      expect(transistion.metadata["message"]).to eq "Prison records requested from #{contact.name}"
    end

    it 'adds the file to the commissioning document' do
      expect {
        service.send!
      }.to change { commissioning_document.attachment }
    end
  end
end
