require 'rails_helper'

describe 'cases/data_requests/show', type: :view do
  context '#show' do
    let(:kase) {
      create(
        :offender_sar_case,
        subject_full_name: 'Robert Badson',
      )
    }

    let(:data_request) {
      create(
        :data_request,
        offender_sar_case: kase,
        location: 'HMP Leicester',
        request_type: 'all_prison_records',
        date_requested: Date.new(2022, 10, 21),
        date_from: Date.new(2018, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(2022, 11, 02),
      )
    }

    let(:commissioning_document) {
      create(
        :commissioning_document,
        template_name: 'prison',
        updated_at: '2023-04-20 15:27'
      )
    }

    context 'data request without commissioning document' do
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_show_page.load(rendered)
        @page = data_request_show_page
      end

      it 'has required content' do
        expect(@page.page_heading.heading.text).to eq 'View data request'
        expect(@page.data.number.text).to eq "#{kase.number} - Robert Badson"
        expect(@page.data.location.text).to eq 'HMP Leicester'
        expect(@page.data.request_type.text).to eq 'All prison records'
        expect(@page.data.date_requested.text).to eq '21 Oct 2022'
        expect(@page.data.date_from.text).to eq '15 Aug 2018'
        expect(@page.data.date_to.text).to eq 'N/A'
        expect(@page.data.pages_received.text).to eq '32'
        expect(@page.data.completed.text).to eq 'Yes'
        expect(@page.data.date_completed.text).to eq '2 Nov 2022'
        expect(@page.link_edit.text).to eq 'Edit data request'
      end
    end

    context 'commissiong document has been selected' do
      before do
        assign(:commissioning_document, commissioning_document.decorate)
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_show_page.load(rendered)
        @page = data_request_show_page
      end

      it 'displays details of the commissioning document' do
        expect(@page.commissioning_document.row.request_document.text).to eq 'Prison records'
        expect(@page.commissioning_document.row.last_updated.text).to eq '20 Apr 2023 15:27'
        expect(@page.commissioning_document.row.sent.text).to eq 'No'
        expect(@page.commissioning_document.row.actions.text).to eq 'Download | Replace | Change'
      end
    end
  end
end
