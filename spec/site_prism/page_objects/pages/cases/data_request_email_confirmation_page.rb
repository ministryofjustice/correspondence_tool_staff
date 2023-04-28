module PageObjects
  module Pages
    module Cases
      class DataRequestEmailConfirmationPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{id}/send_email'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        # element :location, '.data-request__location' 
        element :location, '.data-request__email' 

        section :data, '.grid-row.data-request' do
          element :number, '.data-request__number'
          element :location, '.data_request_location'
          element :request_type, '.data_request_request_type'
          element :date_requested, '.data_request_date_requested'
          element :date_from, '.data_request_date_from'
          element :date_to, '.data_request_date_to'
          element :pages_received, '.data_request_pages_received'
          element :completed, '.data_request_completed'
          element :date_completed, '.data_request_date_completed'
        end

        section :commissioning_document, '.commissioning-document' do
          section :row, 'tbody tr' do
            element :request_document, 'td:nth-child(1)'
            element :last_updated, 'td:nth-child(2)'
            element :sent, 'td:nth-child(3)'
            element :actions, 'td:nth-child(4)'
          end
          element :button_send_email, '.data_request_send_email'
        end

        element :link_edit, '.data-requests__action'
      end
    end
  end
end
