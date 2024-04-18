module PageObjects
  module Sections
    module Cases
      class SAREditDetailsSection < SitePrism::Section
        element :form, ".edit_sar"
        element :subject_name, "#sar_subject_full_name"

        section :third_party, "#third-party" do
          element :yes, "input#sar_third_party_true"
          element :no, "input#sar_third_party_false"
        end

        element :date_received_day, "#sar_received_date_dd"
        element :date_received_month, "#sar_received_date_mm"
        element :date_received_year, "#sar_received_date_yyyy"

        element :case_summary, "#sar_subject"
        element :full_request, "#sar_message"

        element :send_by_email, "#sar_reply_method_send_by_email"
        element :email, "#sar_email"

        element :date_draft_compliant_day, "#sar_date_draft_compliant_dd"
        element :date_draft_compliant_month, "#sar_date_draft_compliant_mm"
        element :date_draft_compliant_year, "#sar_date_draft_compliant_yyyy"
      end
    end
  end
end
