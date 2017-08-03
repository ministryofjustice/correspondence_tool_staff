module PageObjects
  module Pages
    module Teams
      class ShowPage < SitePrism::Page
        set_url '/teams/{id}'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'


        element :heading, 'h1.page-heading'

        section :table_heading, '.table-heading-row' do
          element :name, 'th[area-label="Name column heading"]'
          element :team_leader, 'th[area-label="Team leader column heading"]'
          element :num_subteams, 'th[area-label="Number of sub-teams column heading"]'
        end

        sections :team_list, '.team-row' do
          element :name, 'td[aria-label="Link to team name"]'
          element :team_lead, 'td[aria-label="team lead name"]'
          element :num_children, 'td[aria-label="number of sub teams"]'
          element :actions, 'td[aria-label="Actions"]'
        end

      end
    end
  end
end

