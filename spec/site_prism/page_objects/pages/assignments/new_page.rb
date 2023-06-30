module PageObjects
  module Pages
    module Assignments
      class NewPage < PageObjects::Pages::Base
        include SitePrism::Support::AssignToBusinessUnitHelpers

        set_url "/cases/{case_id}/assignments/new"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :business_groups,
                PageObjects::Sections::Assignments::BusinessGroupSelectorSection,
                "ul.business-groups"
        section :assign_to,
                PageObjects::Sections::Assignments::AssignToBusinessUnitSection,
                "ul.teams"

        element :create_and_assign_case, ".button"
      end
    end
  end
end
