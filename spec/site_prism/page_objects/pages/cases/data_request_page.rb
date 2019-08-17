module PageObjects
  module Pages
    module Cases
      class DataRequestPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/new'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :location,  '#data_request_location'
        element :data,      '#data_request_data'

        element :submit_button, '.button'
      end
    end
  end
end

