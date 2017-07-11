module PageObjects
  module Pages
    module Cases
      class ApproveResponsePage < SitePrism::Page
        set_url '/cases/{id}/approve_response'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :clearance,
                PageObjects::Sections::Cases::ClearanceCopySection, '.clearance-copy'


        element :submit_button, '.button'

      end
    end
  end
end
