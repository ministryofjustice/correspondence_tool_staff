require "rails_helper"

describe "cases/data_request_areas/show", type: :view do
  describe "#show" do
    let(:kase) do
      create(
        :offender_sar_case,
        subject_full_name: "Robert Badson",
      )
    end

    let(:data_request_area) { create :data_request_area, data_request_area_type: "prison", offender_sar_case: kase }

    let!(:commissioning_document) { create :commissioning_document, data_request_area: }

    let(:data_request) do
      create(
        :data_request,
        offender_sar_case: kase,
        data_request_area:,
        request_type: "all_prison_records",
        date_requested: Date.new(2022, 10, 21),
        date_from: Date.new(2018, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(2022, 11, 0o2),
      )
    end

    let(:page) { data_request_area_show_page }

    let(:policy) do
      instance_double("Pundit::Policy").tap do |p|
        allow(view).to receive(:policy).and_return(p)
      end
    end

    let(:can_record_data_request) { true }

    before do
      allow(policy).to receive(:can_record_data_request?).and_return can_record_data_request
    end

    context "when data request area has a data request" do
      before do
        assign(:data_request, data_request)
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, data_request_area.commissioning_document.decorate)
        assign(:request_ready, true)

        render
        data_request_area_show_page.load(rendered)
      end

      it "has required content" do
        row = page.data_requests.rows[0]

        expect(page.page_heading.heading.text).to eq "View prison data request area"
        expect(page.location.text).to eq "HMP halifax"
        expect(row.request_type.text).to eq "All prison records 15 Aug 2018 onwards"
        expect(row.date_requested.text).to eq "21 Oct 2022"
        expect(row.pages.text).to eq "32"
        expect(row.date_received.text).to eq "2 Nov 2022"
        expect(row.status.text).to eq "Completed"
        expect(row.edit.text).to eq "Edit"
      end

      it "displays the send 'commissioning email button'" do
        request_count = data_request_area.data_requests.size
        expect(request_count).to eq 1
        expect(page.commissioning_document.button_send_email.text).to eq "Send commissioning email"
      end
    end

    context "when data request area does not have any data requests" do
      before do
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, data_request_area.commissioning_document.decorate)
        assign(:request_ready, false)

        render
        data_request_area_show_page.load(rendered)
      end

      it "does not display the send 'commissioning email button'" do
        request_count = data_request_area.data_requests.size
        expect(request_count).to eq 0
        expect { page.commissioning_document.button_send_email }.to raise_error(Capybara::ElementNotFound)
      end

      it "confirms no data requests have been recorded" do
        expect(page.data_requests.none.text).to eq "No data requests recorded"
      end
    end

    context "when data request for Other is selected" do
      let(:data_request) do
        create(
          :data_request,
          offender_sar_case: kase,
          data_request_area:,
          request_type: "other",
          request_type_note: "My details of request",
          date_requested: Date.new(2022, 10, 21),
          cached_num_pages: 32,
          completed: true,
          cached_date_received: Date.new(2022, 11, 0o2),
        )
      end

      before do
        assign(:data_request, data_request)
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, data_request_area.commissioning_document.decorate)

        render
        data_request_area_show_page.load(rendered)
      end

      it "has required content" do
        expect(page.page_heading.heading.text).to eq "View prison data request area"
        expect(page.text).to include("#{kase.number} - Robert Badson")
        expect(page.location.text).to eq "HMP halifax"
        expect(page.data_requests.rows.first.request_type.text).to eq("Other:My details of request")
        expect(page.data_requests.rows.first.date_requested.text).to eq "21 Oct 2022"
        expect(page.data_requests.rows.first.pages.text).to eq "32"
        expect(page.data_requests.rows.first.date_received.text).to eq "2 Nov 2022"
        expect(page.data_requests.rows.first.status.text).to eq "Completed"
        expect(page.data_requests.rows.first.edit.text).to eq "Edit"
      end
    end

    context "when commissioning email has been sent" do
      let(:email_address) { "user@prison.gov.uk" }

      before do
        create(:data_request_email, data_request_area:, created_at: "2023-07-07 14:53", email_address:)
        commissioning_document.sent = true
        assign(:commissioning_document, commissioning_document.decorate)
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)

        render
        data_request_area_show_page.load(rendered)
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
  end
end
