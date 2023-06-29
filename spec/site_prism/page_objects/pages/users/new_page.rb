module PageObjects
  module Pages
    module Users
      class NewPage < SitePrism::Page
        set_url "/teams/{team_id}/users/new"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                ".page-heading"

        element :team_id,   "#team_id", visible: false
        element :role,      "#role",    visible: false
        element :full_name, "#user_full_name"
        element :email,     "#user_email"

        element :submit, "form#new_user input[type=submit]"
      end
    end
  end
end
