module PageObjects
  module Pages
    module Teams
      class JoinTeamFormPage < SitePrism::Page
        set_url '/teams/{id}/join_teams_form'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :heading, '.page-heading--primary'
        element :subhead, '.page-heading--secondary'

        section :business_groups, '.business-groups' do
          elements :links, 'li a'
        end

        section :directorates_list, 'ul.teams' do
          sections :directorates, 'li.team' do
            element :directorate_details, 'div.team-details'
            element :move_to_directorate_link, 'div.team-actions a'
          end
        end
      end
    end
  end
end
