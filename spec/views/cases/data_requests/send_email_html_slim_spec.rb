require 'rails_helper'
# require 'site_prism/page_objects/pages/application.rb'

describe 'cases/data_requests/send_email', type: :view do
  context '#send_email' do
    let(:kase) {
      create(
        :offender_sar_case,
        subject_full_name: 'Minnie Mouse',
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

    context 'data request with commissioning document' do
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_email_confirmation_page.load(rendered)
        @page = data_request_email_confirmation_page
      end

      it 'has required content' do
      
        expect(@page.page_heading.heading.text).to eq 'Are you sure you want to send the commissioning email?'
        # expect(@page.submit_button.value).to eq 'Send Commissioning Email'
      end
    end  
  end
end
