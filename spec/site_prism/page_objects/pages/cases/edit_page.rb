module PageObjects
  module Pages
    module Cases
      class EditPage < PageObjects::Pages::Base
        # This page is just a version of the new page.

        set_url '/cases/{id}/edit'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :date_received_day, '#case_received_date_dd'
        element :date_received_month, '#case_received_date_mm'
        element :date_received_year, '#case_received_date_yyyy'

        element :subject, '#case_subject'
        element :full_request, '#case_message'
        element :full_name, '#case_name'
        element :email, '#case_email'
        element :address, '#case_postal_address'

        element :type_of_requester, :xpath,
                '//fieldset[contains(.,"Type of requester")]'

        element :submit_button, '.button'

      end
    end
  end
end
