module PageObjects
  module Pages
    module Assignments
      class NewPage < PageObjects::Pages::Base
        set_url '/cases/{case_id}/assignments/new'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :assign_to, 'ul.teams' do
          sections :team, 'li.team' do
            element :business_unit, '.team-unit-name'
            element :assign_link, '.team-actions a'
          end
        end

        element :create_and_assign_case, '.button'

        def choose_assignment_team(team)
          make_radio_button_choice "assignment_team_id_#{team.id}"
        end
      end
    end
  end
end
