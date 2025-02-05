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

    let(:in_progress_data_request) { create(:data_request)}

    let(:page) { data_request_area_show_page }

    let(:policy) do
      instance_double("Pundit::Policy").tap do |p|
        allow(view).to receive(:policy).and_return(p)
      end
    end

    let(:can_record_data_request) { true }
    let(:can_send_day_1_email) { true }

    before do
      allow(policy).to receive(:can_record_data_request?).and_return can_record_data_request
      allow(policy).to receive(:can_send_day_1_email?).and_return can_send_day_1_email
    end

    context "when Offender SAR Case data request area has a data request" do
      before do
        data_request_area.data_requests << data_request
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, data_request_area.commissioning_document.decorate)
        assign(:sent_emails, [])

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

      it "translates the data_request_area_type using the relevant key" do
        translated_area_type = I18n.t("helpers.label.data_request_area.headers.data_request_area_type.#{data_request_area.data_request_area_type}")
        expect(page.page_heading.heading.text).to eq "View #{translated_area_type} data request area"
      end
    end

    context "when Offender SAR Complaint Case data request area has a data request" do
      let(:kase_offender_sar_complaint) do
        create(
          :offender_sar_complaint,
          current_state: "to_be_assessed",
        )
      end

      let(:data_request_area) { create :data_request_area, data_request_area_type: "prison", offender_sar_case: kase_offender_sar_complaint }

      let(:can_send_day_1_email) { false }

      before do
        data_request_area.data_requests << in_progress_data_request
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, data_request_area.commissioning_document.decorate)

        render
        data_request_area_show_page.load(rendered)
      end

      it "without the send 'commissioning email button'" do
        request_count = data_request_area.data_requests.size
        expect(request_count).to eq 1
        expect { page.commissioning_document.button_send_email }.to raise_error(Capybara::ElementNotFound)
      end
    end

    context "when data request area does not have any data requests" do
      before do
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)
        assign(:commissioning_document, data_request_area.commissioning_document.decorate)

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
        data_request_area.data_requests << data_request
        assign(:data_request_area, data_request_area.decorate)
        assign(:case, data_request_area.kase)

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
      let(:current_data_request) { in_progress_data_request }

      before do
        Timecop.freeze(Time.zone.local(2023, 7, 15)) do
          data_request_area.data_requests << current_data_request
          commissioning_document.update!(sent_at: Date.new(2023, 7, 7))
          create(:data_request_email, data_request_area:, created_at: "2023-07-07 14:53", email_address:)
          assign(:commissioning_document, commissioning_document.decorate)
          assign(:data_request_area, data_request_area.decorate)
          assign(:case, data_request_area.kase)
          assign(:sent_emails, data_request_area.data_request_emails.order(created_at: :desc).map(&:decorate))

          render
          data_request_area_show_page.load(rendered)
        end
      end

      it "displays Download link" do
        expect(page.commissioning_document.row.actions.text).to eq "Download"
      end

      it "does not display send email button" do
        expect { page.commissioning_document.button_send_email }.to raise_error(Capybara::ElementNotFound)
      end

      it "does not display add data request type button" do
        expect(page).to have_no_link("Add data request type", href: new_case_data_request_area_data_request_path(data_request_area.kase, data_request_area))
      end

      it "does not display delete button" do
        expect(page).to have_no_link("Delete", href: case_data_request_area_path(data_request_area.kase, data_request_area))
      end

      it "displays email details" do
        expect(page.commissioning_document.email_row.email_type.text).to eq "Day 1 commissioning email"
        expect(page.commissioning_document.email_row.email_address.text).to eq email_address
        expect(page.commissioning_document.email_row.created_at.text).to eq "7 Jul 2023 14:53"
        expect(page.commissioning_document.email_row.status.text).to eq "Created"
      end

      it "displays next chase date" do
        Timecop.freeze(Time.zone.local(2023, 7, 15)) do
          expect(page.commissioning_document.next_chase_description.text).to eq "Chase 1 will be sent on 15 Jul 2023"
        end
      end

      context "when data requests are complete" do
        let(:current_data_request) { data_request }

        it "does not display next chase date" do
          expect { page.commissioning_document.next_chase_description }.to raise_error(Capybara::ElementNotFound)
        end
      end
    end

    context "when commissioning email has not been sent" do
      before do
        data_request_area.data_requests << in_progress_data_request
        assign(:commissioning_document, commissioning_document.decorate)
        assign(:data_request_area, data_request_area.decorate)
        assign(:data_request, data_request.decorate)
        assign(:case, data_request_area.kase)

        render
        data_request_area_show_page.load(rendered)
      end

      it "displays send email button" do
        expect(page.commissioning_document.button_send_email.text).to eq "Send commissioning email"
        expect(page).to have_selector(".data_request_area_send_email")
      end

      it "displays add data request type button" do
        expect(page).to have_link("Add data request type", href: new_case_data_request_area_data_request_path(data_request_area.kase, data_request_area))
      end

      it "displays delete button" do
        expect(page).to have_link("Delete", href: case_data_request_area_path(data_request_area.kase, data_request_area))
      end

      it "does not display email details section" do
        expect { page.commissioning_document.email_row }.to raise_error(Capybara::ElementNotFound)
      end
    end
  end
end
