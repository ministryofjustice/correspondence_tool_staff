require "rails_helper"

RSpec.describe "cases/data_requests/show", type: :view do
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
        data_request_area:,
        request_type: "nomis_other",
        request_type_note: "My details of request",
        date_requested: Date.new(2022, 10, 21),
        date_from: Date.new(2018, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(2022, 11, 0o2),
      )
    end

    let(:data_request_area) do
      create(
        :data_request_area,
        offender_sar_case: kase,
        location: "HMP Leicester",
      )
    end

    let(:data_request) do
      create(
        :data_request,
        offender_sar_case: kase,
        request_type: "all_prison_records",
        date_requested: Date.new(2022, 10, 21),
        date_from: Date.new(2018, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(2022, 11, 0o2),
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
      assign(:data_request_area, data_request_area.decorate)
      assign(:data_request, data_request.decorate)
      assign(:case, data_request_area.kase)

      render
      data_request_show_page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.heading.text).to eq "View data request"
      expect(page.data.number.text).to eq "#{kase.number} - Robert Badson"
      expect(page.data.location.text).to eq "HMP halifax"
      expect(page.data.request_type.text).to eq "All prison records"
      expect(page.data.date_requested.text).to eq "21 Oct 2022"
      expect(page.data.date_from.text).to eq "15 Aug 2018"
      expect(page.data.date_to.text).to eq "N/A"
      expect(page.data.pages_received.text).to eq "32"
      expect(page.data.completed.text).to eq "Yes"
      expect(page.data.date_completed.text).to eq "2 Nov 2022"
      expect(page.link_edit.text).to eq "Edit data request"
    end

    context "when case is closed" do
      let(:can_record_data_request) { false }

      before do
        assign(:data_request_area, data_request_area.decorate)
        assign(:data_request, data_request.decorate)
        assign(:case, data_request_area.kase)

        render
        data_request_show_page.load(rendered)
      end

      it "does not have edit link" do
        expect(page).not_to have_link_edit
      end
    end
  end
end
