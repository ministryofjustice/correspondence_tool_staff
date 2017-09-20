module PageObjects
  module Pages
    module Teams
      class EditPage < SitePrism::Page
        set_url '/teams/{id}/edit'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :name, '#team_name'
        element :email, '#team_email'
        element :deputy_director, '#team_team_lead'
        element :lead, '#team_team_lead'

        element :submit_button, '.button'


      end
    end
  end
end

