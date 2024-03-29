require "rails_helper"

describe "cases/data_requests/probation_send_email", type: :view do
  describe "#send_email" do
    let(:kase) do
      create(
        :offender_sar_case,
        subject_full_name: "Minnie Mouse",
      )
    end

    let(:data_request) do
      create(
        :data_request,
        offender_sar_case: kase,
      )
    end

    let(:commissioning_document) do
      create(
        :commissioning_document,
        template_name: "probation",
        updated_at: "2023-04-20 15:27",
      )
    end

    let(:page) { data_request_send_probation_email_page }

    context "with data request with probation template" do
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)
        assign(:commissioning_document, commissioning_document)
        assign(:email, ProbationCommissioningDocumentEmail.new)

        render
        data_request_send_probation_email_page.load(rendered)
      end

      it "has required content" do
        expect(page.page_heading.heading.text).to eq "Do you want to send the commissioning email to Branston Archives?"
        expect(page.button_continue.value).to eq "Continue"
        expect(page.link_cancel.text).to eq "Cancel"
      end
    end
  end
end
