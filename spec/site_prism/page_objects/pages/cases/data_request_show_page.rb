module PageObjects
  module Pages
    module Cases
      class DataRequestShowPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{id}'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'


        section :data, '.grid-row.data-request' do
          element :number, '.data-request__number'
          element :location, '.data_request_location'
          element :request_type, '.data_request_request_type'
          element :date_requested, '.data_request_date_requested'
          element :date_from, '.data_request_date_from'
          element :date_to, '.data_request_date_to'
          element :pages_received, '.data_request_pages_received'
          element :completed, '.data_request_completed'
        end

        element :button_select_document, '.data_request_select_document'
        element :link_edit, '.data-requests__action'
      end
    end
  end
end
