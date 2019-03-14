module PageObjects
  module Sections
    module Cases
      class SarEditDetailsSection < SitePrism::Section
        element :form, '.edit_case_sar'
        element :subject_name, '#case_sar_subject_full_name'

        section :third_party, '#third-party' do
          element :yes, 'input#case_sar_third_party_true'
          element :no, 'input#case_sar_third_party_false'
        end

        element :date_received_day, '#case_sar_received_date_dd'
        element :date_received_month, '#case_sar_received_date_mm'
        element :date_received_year, '#case_sar_received_date_yyyy'

        element :case_summary, '#case_sar_subject'
        element :full_request, '#case_sar_message'

        element :send_by_email, '#case_sar_reply_method_send_by_email'
        element :email, '#case_sar_email'

        element :date_draft_compliant_day, '#case_sar_date_draft_compliant_dd'
        element :date_draft_compliant_month, '#case_sar_date_draft_compliant_mm'
        element :date_draft_compliant_year, '#case_sar_date_draft_compliant_yyyy'
      end
    end
  end
end
