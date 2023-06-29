module PageObjects
  module Pages
    module Assignments
      class AssignToTeamMemberPage < PageObjects::Pages::Base
        set_url "/cases/{case_id}/assignments/assign_to_team_member"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :team_members, :xpath, '//fieldset[contains(.,"Choose a new team member for this case")]' do
          elements :users, "label"
        end

        element :confirm_button, ".button"

        def choose_assignment_user(user)
          make_radio_button_choice "assignment_user_id_#{user.id}"
        end
      end
    end
  end
end
