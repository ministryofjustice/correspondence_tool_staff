require "rails_helper"

describe CommissioningDocumentDecorator, type: :model do
  let(:commissioning_document_sent) { create(:commissioning_document, sent: true).decorate }
  let(:commissioning_document_unsent) { create(:commissioning_document, sent: false).decorate }

  describe :sent do
    it "returns No if the commissioning document has not been sent" do
      expect(commissioning_document_unsent.sent).to eq "No"
    end

    it "returns Yes if the commissioning document has been sent" do
      expect(commissioning_document_sent.sent).to eq "Yes"
    end
  end

  describe :request_document do
    it "gets translation for template name" do
      expect(commissioning_document_sent.request_document).to eq "Prison records"
    end
  end

  describe :updated_at do
    it "formats the updated date and time" do
      Timecop.freeze Time.zone.local(2023, 1, 30, 15, 52, 22) do
        commissioning_document_sent.update!(template_name: "probation")
        expect(commissioning_document_sent.updated_at).to eq "30 Jan 2023 15:52"
      end
    end
  end

  describe :download_link do
    it "returns a download link" do
      path = "/cases/#{commissioning_document_sent.data_request.case_id}/data_requests/#{commissioning_document_sent.data_request_id}/commissioning_documents/#{commissioning_document_sent.id}/download"
      expect(commissioning_document_sent.download_link).to include(path)
      expect(commissioning_document_sent.download_link).to include("<a href")
    end
  end

  describe :replace_link do
    it "returns a replace link" do
      path = "/cases/#{commissioning_document_sent.data_request.case_id}/data_requests/#{commissioning_document_sent.data_request_id}/commissioning_documents/#{commissioning_document_sent.id}/replace"
      expect(commissioning_document_sent.replace_link).to include(path)
      expect(commissioning_document_sent.replace_link).to include("<a href")
    end
  end

  describe :change_link do
    it "returns a change link" do
      path = "/cases/#{commissioning_document_sent.data_request.case_id}/data_requests/#{commissioning_document_sent.data_request_id}/commissioning_documents/#{commissioning_document_sent.id}/edit"
      expect(commissioning_document_sent.change_link).to include(path)
      expect(commissioning_document_sent.change_link).to include("<a href")
    end
  end
end
