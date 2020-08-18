module PageObjects
  module Pages
    module Cases
      class DataRequestEditPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{id}{/edit}'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :location, '.data-request__location'
        element :request_type, '.data-request__request_type'

        section :form, 'form#edit_data_request' do

          element :cached_num_pages, 'input[name*="[cached_num_pages]"]'
        end

        element :submit_button, '.button'
      end
    end
  end
end
