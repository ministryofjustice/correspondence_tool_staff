module PageObjects
  module Pages
    module Assignments
      class AssignToNewTeamPage < SitePrism::Page
        include SitePrism::Support::AssignToBusinessUnitHelpers

        set_url "/cases/{case_id}/assign_to_new_team/{id}"

        section :business_groups,
                PageObjects::Sections::Assignments::BusinessGroupSelectorSection,
                "ul.business-groups"
        section :assign_to,
                PageObjects::Sections::Assignments::AssignToBusinessUnitSection,
                "ul.teams"

        element :submit_button, ".button"
      end
    end
  end
end
