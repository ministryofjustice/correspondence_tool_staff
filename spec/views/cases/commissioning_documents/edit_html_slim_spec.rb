require "rails_helper"

describe "cases/commissioning_documents/edit", type: :view do
  describe "#edit" do
    let(:data_request) { create(:data_request) }
    let(:commissioning_document) { create(:commissioning_document, data_request:) }
    let(:page) { edit_commissioning_document_page }

    before do
      assign(:data_request, data_request)
      assign(:case, data_request.kase)
      assign(:commissioning_document, commissioning_document)

      render
      edit_commissioning_document_page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.heading.text).to eq "Select Day 1 request document"
      expect(page.form).to have_template_name
      expect(page.form.submit_button.value).to eq "Generate Day 1 request document"
    end
  end
end
