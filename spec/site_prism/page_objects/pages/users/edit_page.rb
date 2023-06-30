module PageObjects
  module Pages
    module Users
      class EditPage < SitePrism::Page
        set_url "/users/{user_id}/edit"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                ".page-heading"

        element :full_name, "#user_full_name"
        element :email,     "#user_email"
        element :edit_team_member, "form#edit_user input[type=submit]"
        element :deactivate_user_button, "a#deactivate-user-button"
      end
    end
  end
end
