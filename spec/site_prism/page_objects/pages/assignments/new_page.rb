module PageObjects
  module Pages
    module Assignments
      class NewPage < PageObjects::Pages::Base
        set_url '/cases/{case_id}/assignments/new'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :business_groups, 'ul.business-groups' do
          elements :links, 'li a'
          elements :group, 'li.business-group'
          element :all_groups, 'li.show-all'
        end

        section :assign_to, 'ul.teams' do
          sections :team, 'li.team' do
            element :business_unit, '.team-unit-name'
            element :assign_link, '.team-actions a'
            elements :areas_covered, '.areas-covered li'
            element :deputy_director, '.deputy-director'
          end
        end

        element :create_and_assign_case, '.button'

        def choose_business_unit(team)
          business_unit = assign_to.find('h3 div', text: team.name)
          container = business_unit.find(:xpath, '../../..')
          container.find('a.button').click
        end

        def choose_business_group(group)
          business_groups.find_link(group.name).click
        end
      end
    end
  end
end
