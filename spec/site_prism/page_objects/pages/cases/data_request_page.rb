module PageObjects
  module Pages
    module Cases
      class DataRequestPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/new'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :form, '#edit_case' do
          elements :location, 'input[name*="[location]"]'
          elements :data, 'input[name*="[data]"]'
        end

        element :submit_button, '.button'
      end
    end
  end
end

