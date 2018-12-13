module PageObjects
  module Pages
    module Cases
      class ApprovePage < SitePrism::Page
        set_url '/cases/{id}/approve'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :clearance,
                PageObjects::Sections::Cases::ClearanceCopySection, '.clearance-copy'
        section :bypass_press_option,
                PageObjects::Sections::Cases::BypassPressOfficeOptionSection, '#bypass-press-office-option'

        element :clear_response_button, '.button'

      end
    end
  end
end
