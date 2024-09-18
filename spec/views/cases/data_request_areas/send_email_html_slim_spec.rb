require "rails_helper"

RSpec.describe "cases/data_request_areas/send_email", type: :view do
  describe "#send_email" do
    let(:kase) do
      create(
        :offender_sar_case,
        subject_full_name: "Minnie Mouse",
      )
    end

    let(:data_request_area) do
      create(
        :data_request_area,
        offender_sar_case: kase,
      )
    end

    let(:commissioning_document) do
      create(
        :commissioning_document,
        data_request_area:,
      )
    end

    let(:page) { data_request_email_confirmation_page }

    context "with data request with contact without email address" do
      before do
        assign(:data_request_area, data_request_area)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, commissioning_document)
        assign(:recipient_emails, [])
        assign(:no_email_present, true)

        render
        data_request_email_confirmation_page.load(rendered)
      end

      it "has required content" do
        expect(page.page_heading.heading.text).to eq "Are you sure you want to send the commissioning email?"
        expect(page.page_banner.text).to include "The selected location does not have an email address. Please update or select another."
        expect(page.button_send_email.disabled?).to eq true
        expect(page.link_cancel.text).to eq "Cancel"
      end
    end

    context "with data request with contact which has email address" do
      before do
        assign(:data_request_area, data_request_area)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, commissioning_document)
        assign(:recipient_emails, ["oscar@grouch.com"])

        render
        data_request_email_confirmation_page.load(rendered)
      end

      it "has required content" do
        expect(page.page_heading.heading.text).to eq "Are you sure you want to send the commissioning email?"
        expect(page.button_send_email.value).to eq "Send commissioning email"
        expect(page.link_cancel.text).to eq "Cancel"
      end
    end
  end
end
