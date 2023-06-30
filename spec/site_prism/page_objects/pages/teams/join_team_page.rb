module PageObjects
  module Pages
    module Teams
      class JoinTeamPage < SitePrism::Page
        set_url "/teams/{id}/join_teams"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :heading, ".page-heading--primary"
        element :subhead, ".page-heading--secondary"

        section :bg_selector, ".bg-selector" do
          element :bg_select_menu, "select"
        end

        section :directorate_selector, ".directorate-selector" do
          element :directorate_select_menu, "select"
        end

        section :bu_selector, ".bu-selector" do
          element :bg_list, "select"
        end

        section :bu_list, "ul.teams" do
          sections :teams, "li.team" do
            element :team_details, "div.team-details"
            element :join_team_link, "div.team-actions a"
          end
        end

        def find_row(team_name)
          bu_list.teams.find do |item|
            item.team_details.text == team_name
          end
        end
      end
    end
  end
end
