module PageObjects
  module Sections
    module Cases
      class FoiEditDetailsSection < SitePrism::Section
        element :form, '.edit_case_foi'
        element :date_received_day, '#case_foi_received_date_dd'
        element :date_received_month, '#case_foi_received_date_mm'
        element :date_received_year, '#case_foi_received_date_yyyy'

        element :subject, '#case_foi_subject'
        element :full_request, '#case_foi_message'
        element :full_name, '#case_foi_name'
        element :email, '#case_foi_email'
        element :address, '#case_foi_postal_address'

        element :type_of_requester, :xpath,
                '//fieldset[contains(.,"Type of requester")]'
      end
    end
  end
end

