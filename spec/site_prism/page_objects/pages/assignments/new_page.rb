module PageObjects
  module Pages
    module Assignments
      class NewPage < PageObjects::Pages::Base
        set_url '/cases/{id}/assignments/new'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :assign_to, :xpath, '//fieldset[contains(.,"Assign to")]' do
          elements :teams, 'label'
        end

        element :create_and_assign_case, '.button'

        def choose_assignment_team(team)
          make_radio_button_choice "assignment_team_id_#{team.id}"
        end
      end
    end
  end
end
