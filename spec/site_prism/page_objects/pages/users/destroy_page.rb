module PageObjects
  module Pages
    module Users
      class DestroyPage < SitePrism::Page
        set_url 'users/{user_id}/confirm_destroy/{team_id}'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                '.page-heading'

        element :deactivate_user_button, 'a#deactivate-user-button'

        element :cancel, 'a.acts-like-button.left-spacing'
      end
    end
  end
end
