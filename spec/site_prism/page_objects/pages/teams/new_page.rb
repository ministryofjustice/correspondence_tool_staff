module PageObjects
  module Pages
    module Teams
      class NewPage < ::PageObjects::Pages::Base
        set_url '/teams/new'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :name, '#team_name'
        element :email, '#team_email'
        element :deputy_director, '#team_team_lead'
        element :lead, '#team_team_lead'

        #Business Group
        element :business_group_label, 'label[for="team_name_business_group"]'
        element :business_group_email_label, 'label[for="team_email_business_group_email"]'
        element :director_general_label, 'label[for="team_team_lead_director_general"]'

        #Directorate
        element :directorate_label, 'label[for="team_name_directorate"]'
        element :directorate_email_label, 'label[for="team_email_directorate_email"]'
        element :director_label, 'label[for="team_team_lead_director"]'

        #Business Unit
        element :business_unit_label, 'label[for="team_name_business_unit"]'
        element :business_unit_email_label, 'label[for="team_email_business_unit_email"]'
        element :deputy_director_label, 'label[for="team_team_lead_deputy_director"]'

        element :responding_role_option, :xpath, '//input[@value="responder"]//..'
        element :approving_role_option, :xpath, '//input[@value="approver"]//..'
        element :managing_role_option, :xpath, '//input[@value="manager"]//..'

        element :submit_button, '.button'
      end
    end
  end
end
