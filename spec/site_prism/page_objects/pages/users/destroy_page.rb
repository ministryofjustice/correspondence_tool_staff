module PageObjects
  module Pages
    module Users
      class DestroyPage < SitePrism::Page
        set_url "teams/{team_id}/users/{user_id}/confirm_destroy"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                ".page-heading"

        element :deactivate_info, ".deactivate-info"

        element :other_team_info, ".other-team-info"

        element :deactivate_user_button, "a#deactivate-user-button"

        element :cancel, "a.acts-like-button.left-spacing"
      end
    end
  end
end
