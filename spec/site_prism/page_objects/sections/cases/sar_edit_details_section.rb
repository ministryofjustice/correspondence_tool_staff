module PageObjects
  module Sections
    module Cases
      class SarEditDetailsSection < SitePrism::Section
        element :form, '.edit_case_sar'
        element :subject_name, '#case_sar_subject_full_name'
#  3rd third_party
# element :type_of_requester, :xpath,
#         '//fieldset[contains(.,"Type of requester")]'

        element :date_received_day, '#case_sar_received_date_dd'
        element :date_received_month, '#case_sar_received_date_mm'
        element :date_received_year, '#case_sar_received_date_yyyy'

        element :case_summary, '#case_sar_subject'
        element :full_request, '#case_sar_message'

# reply method
# element :email, '#case_sar_email'
        element :date_draft_compliant_day, '#case_sar_date_draft_compliant_dd'
        element :date_draft_compliant_month, '#case_sar_date_draft_compliant_mm'
        element :date_draft_compliant_year, '#case_sar_date_draft_compliant_yyyy'

      end
    end
  end
end
