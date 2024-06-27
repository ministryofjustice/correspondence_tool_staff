require "rails_helper"

describe "cases/data_requests/show", type: :view do
  describe "#show" do
    let(:kase) do
      create(
        :offender_sar_case,
        subject_full_name: "Robert Badson",
      )
    end

    let(:data_request_other) do
      create(
        :data_request,
        offender_sar_case: kase,
        location: "HMP Leicester",
        request_type: "nomis_other",
        request_type_note: "My details of request",
        date_requested: Date.new(2022, 10, 21),
        date_from: Date.new(2018, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(2022, 11, 0o2),
      )
    end

    let(:data_request) do
      create(
        :data_request,
        offender_sar_case: kase,
        location: "HMP Leicester",
        request_type: "all_prison_records",
        date_requested: Date.new(2022, 10, 21),
        date_from: Date.new(2018, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(2022, 11, 0o2),
      )
    end

    let(:commissioning_document) do
      create(
        :commissioning_document,
        template_name: "prison",
        updated_at: "2023-04-20 15:27",
      )
    end

    let(:page) { data_request_show_page }

    let(:policy) do
      instance_double("Pundit::Policy").tap do |p|
        allow(view).to receive(:policy).and_return(p)
      end
    end

    let(:can_record_data_request) { true }

    before do
      allow(policy).to receive(:can_record_data_request?).and_return can_record_data_request
    end

    context "when data request without commissioning document" do
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_show_page.load(rendered)
      end

      it "has required content" do
        expect(page.page_heading.heading.text).to eq "View data request"
        expect(page.data.number.text).to eq "#{kase.number} - Robert Badson"
        expect(page.data.location.text).to eq "HMP Leicester"
        expect(page.data.request_type.text).to eq "All prison records"
        expect(page.data.date_requested.text).to eq "21 Oct 2022"
        expect(page.data.date_from.text).to eq "15 Aug 2018"
        expect(page.data.date_to.text).to eq "N/A"
        expect(page.data.pages_received.text).to eq "32"
        expect(page.data.completed.text).to eq "Yes"
        expect(page.data.date_completed.text).to eq "2 Nov 2022"
        expect(page.link_edit.text).to eq "Edit data request"
      end
    end

    context "when data request for Nomis other records is selected" do
      before do
        assign(:data_request, data_request_other)
        assign(:case, data_request.kase)

        render
        data_request_show_page.load(rendered)
      end

      it "has required content" do
        expect(page.page_heading.heading.text).to eq "View data request"
        expect(page.data.number.text).to eq "#{kase.number} - Robert Badson"
        expect(page.data.location.text).to eq "HMP Leicester"
        expect(page.data.request_type.text).to eq ("NOMIS other:\n My details of request")
        expect(page.data.date_requested.text).to eq "21 Oct 2022"
        expect(page.data.date_from.text).to eq "15 Aug 2018"
        expect(page.data.date_to.text).to eq "N/A"
        expect(page.data.pages_received.text).to eq "32"
        expect(page.data.completed.text).to eq "Yes"
        expect(page.data.date_completed.text).to eq "2 Nov 2022"
        expect(page.link_edit.text).to eq "Edit data request"
      end
    end

    context "when commissioning document has been selected" do
      before do
        assign(:commissioning_document, commissioning_document.decorate)
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_show_page.load(rendered)
      end

      it "displays details of the commissioning document" do
        expect(page.commissioning_document.row.request_document.text).to eq "Prison records"
        expect(page.commissioning_document.row.last_updated.text).to eq "20 Apr 2023 15:27"
        expect(page.commissioning_document.row.actions.text).to eq "Download | Replace | Change"
      end

      it "displays send email button" do
        expect(page.commissioning_document.button_send_email.text).to eq "Send commissioning email"
      end
    end

    context "when commissioning email has been sent" do
      let(:email_address) { "user@prison.gov.uk" }

      before do
        create(:data_request_email, data_request:, created_at: "2023-07-07 14:53", email_address:)
        commissioning_document.sent = true
        assign(:commissioning_document, commissioning_document.decorate)
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_show_page.load(rendered)
      end

      it "only displays Download link" do
        expect(page.commissioning_document.row.actions.text).to eq "Download"
      end

      it "does not display send email button" do
        expect { page.commissioning_document.button_send_email }.to raise_error(Capybara::ElementNotFound)
      end

      it "displays email details" do
        expect(page.commissioning_document.email_row.email_type.text).to eq "Day 1 commissioning email"
        expect(page.commissioning_document.email_row.email_address.text).to eq email_address
        expect(page.commissioning_document.email_row.created_at.text).to eq "7 Jul 2023 14:53"
        expect(page.commissioning_document.email_row.status.text).to eq "Created"
      end
    end

    context "when case is closed" do
      let(:can_record_data_request) { false }

      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_show_page.load(rendered)
      end

      it "does not have edit link" do
        expect(page).not_to have_link_edit
      end
    end
  end
end
