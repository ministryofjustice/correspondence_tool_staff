module PageObjects
  module Pages
    module Cases
      class DataRequestEditPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{id}/edit'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :location, '.data-request__location'
        element :data, '.data-request__data'

        section :form, 'form#new_data_request_log' do
          element :date_received_dd,   'input[name*="[date_received_dd]"]'
          element :date_received_mm,   'input[name*="[date_received_mm]"]'
          element :date_received_yyyy, 'input[name*="[date_received_yyyy]"]'

          element :num_pages, 'input[name*="[num_pages]"]'
        end

        element :submit_button, '.button'
      end
    end
  end
end

