require "rails_helper"

describe CommissioningDocumentDecorator, type: :model do
  let(:commissioning_document) { create(:commissioning_document).decorate }

  describe ":request_document" do
    it "gets translation for template name" do
      expect(commissioning_document.request_document).to eq "Prison records"
    end
  end

  describe ":updated_at" do
    it "formats the updated date and time" do
      Timecop.freeze Time.zone.local(2023, 1, 30, 15, 52, 22) do
        commissioning_document.update!(template_name: "probation")
        expect(commissioning_document.updated_at).to eq "30 Jan 2023 15:52"
      end
    end
  end

  describe ":download_link" do
    it "returns a download link" do
      path = "/cases/#{commissioning_document.data_request.case_id}/data_requests/#{commissioning_document.data_request_id}/commissioning_documents/#{commissioning_document.id}/download"
      expect(commissioning_document.download_link).to include(path)
      expect(commissioning_document.download_link).to include("<a href")
    end
  end

  describe ":replace_link" do
    it "returns a replace link" do
      path = "/cases/#{commissioning_document.data_request.case_id}/data_requests/#{commissioning_document.data_request_id}/commissioning_documents/#{commissioning_document.id}/replace"
      expect(commissioning_document.replace_link).to include(path)
      expect(commissioning_document.replace_link).to include("<a href")
    end
  end

  describe ":change_link" do
    it "returns a change link" do
      path = "/cases/#{commissioning_document.data_request.case_id}/data_requests/#{commissioning_document.data_request_id}/commissioning_documents/#{commissioning_document.id}/edit"
      expect(commissioning_document.change_link).to include(path)
      expect(commissioning_document.change_link).to include("<a href")
    end
  end
end
