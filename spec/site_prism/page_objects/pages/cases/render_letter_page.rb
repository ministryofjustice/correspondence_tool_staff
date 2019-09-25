module PageObjects
  module Pages
    module Cases
      class RenderLetterPage < SitePrism::Page
        set_url '/cases/{case_id}/letters/{type}/render'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

      end
    end
  end
end

