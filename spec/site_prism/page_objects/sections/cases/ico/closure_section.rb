module PageObjects
  module Sections
    module Cases
      module ICO
        class ClosureSection < SitePrism::Section

          section :ico_decision, '.ico-decision' do
            element :overturned, '#case_ico_ico_decision_overturned'
            element :overturned_label, 'label[for="case_ico_ico_decision_overturned"]'
            element :upheld, '#case_ico_ico_decision_upheld'
            element :upheld_label, 'label[for="case_ico_ico_decision_upheld"]'
          end

          element :date_ico_decision_received_day, :case_form_element, 'date_ico_decision_received_dd'
          element :date_ico_decision_received_month, :case_form_element, 'date_ico_decision_received_mm'
          element :date_ico_decision_received_year, :case_form_element, 'date_ico_decision_received_yyyy'

          section :uploads, '#uploaded-ico-decision-files-fields' do
            element :label, 'span.form-label-bold'
            element :hint, 'span.form-hint'
          end
          section :missing_info, '.missing-info' do
            element :yes, 'label[for="case_sar_missing_info_yes"]'
            element :no, 'label[for="case_sar_missing_info_no"]'
          end
        end
      end
    end
  end
end
