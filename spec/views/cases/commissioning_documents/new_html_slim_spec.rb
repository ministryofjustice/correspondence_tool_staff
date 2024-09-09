require "rails_helper"

xdescribe "cases/commissioning_documents/new", type: :view do
  describe "#new" do
    let(:data_request) { create(:data_request) }
    let(:commissioning_document) { CommissioningDocument.new(data_request:) }
    let(:page) { new_commissioning_document_page }

    before do
      assign(:data_request, data_request)
      assign(:case, data_request.kase)
      assign(:commissioning_document, commissioning_document)

      render
      new_commissioning_document_page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.heading.text).to eq "Select Day 1 request document"
      expect(page.form).to have_template_name
      expect(page.form.submit_button.value).to eq "Generate Day 1 request document"
    end
  end
end
