module PageObjects
  module Pages
    module Cases
      class DataRequestPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests{/new}'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :form, '#new_data_request' do
          element :location, 'input[name*="[location]"]'
          element :request_type, 'input[name*="[request_type]"]'
          element :submit_button, '.button'
        end
      end
    end
  end
end
