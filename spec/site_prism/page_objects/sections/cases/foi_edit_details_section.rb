module PageObjects
  module Sections
    module Cases
      class FOIEditDetailsSection < SitePrism::Section
        element :form, ".edit_foi"
        element :date_received_day, "#foi_received_date_dd"
        element :date_received_month, "#foi_received_date_mm"
        element :date_received_year, "#foi_received_date_yyyy"

        element :subject, "#foi_subject"
        element :full_request, "#foi_message"
        element :full_name, "#foi_name"
        element :email, "#foi_email"
        element :address, "#foi_postal_address"
        element :date_draft_compliant_day, "#foi_date_draft_compliant_dd"
        element :date_draft_compliant_month, "#foi_date_draft_compliant_mm"
        element :date_draft_compliant_year, "#foi_date_draft_compliant_yyyy"

        element :type_of_requester, :xpath,
                '//fieldset[contains(.,"Type of requester")]'
      end
    end
  end
end
