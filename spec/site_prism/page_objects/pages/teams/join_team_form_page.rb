module PageObjects
  module Pages
    module Teams
      class JoinTeamFormPage < SitePrism::Page
        set_url "/teams/{id}/join_teams_form"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :heading, ".page-heading--primary"
        element :subhead, ".page-heading--secondary"

        element :join_button, ".join-team-button"
      end
    end
  end
end
