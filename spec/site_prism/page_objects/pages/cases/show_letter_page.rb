module PageObjects
  module Pages
    module Cases
      class ShowLetterPage < SitePrism::Page
        set_url "/cases/{case_id}/letters/{type}"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"
      end
    end
  end
end
