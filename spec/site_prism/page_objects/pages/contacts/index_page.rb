module PageObjects
  module Pages
    module Contacts
      class IndexPage < PageObjects::Pages::Base
        include SitePrism::Support::AssignToBusinessUnitHelpers

        set_url "/contacts"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"
      end
    end
  end
end
