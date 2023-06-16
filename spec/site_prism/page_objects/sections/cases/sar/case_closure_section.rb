module PageObjects
  module Sections
    module Cases
      module SAR
        class CaseClosureSection < SitePrism::Section
          element :date_responded_day, :case_form_element, "date_responded_dd"
          element :date_responded_month, :case_form_element, "date_responded_mm"
          element :date_responded_year, :case_form_element, "date_responded_yyyy"

          section :missing_info, ".missing-info" do
            element :yes, 'label[for="sar_missing_info_yes"]'
            element :no, 'label[for="sar_missing_info_no"]'
          end
        end
      end
    end
  end
end
