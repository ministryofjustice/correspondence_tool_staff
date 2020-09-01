module PageObjects
  module Pages
    module Cases
      class CoverPage < SitePrism::Page
        set_url '/cases/{id}/cover-page'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :data_requests,
          PageObjects::Sections::Cases::DataRequestsSection, '.data-requests'

        element :final_deadline, '.heading--final-deadline'
      end
    end
  end
end
