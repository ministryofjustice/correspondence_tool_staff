module PageObjects
  module Sections
    module Cases
      class TypeFilterPanelSection < SitePrism::Section
        element :foi_standard_checkbox, '#search_query_filter_case_type_foi-standard'
        element :foi_ir_compliance_checkbox, '#search_query_filter_case_type_foi-ir-compliance'
        element :foi_ir_timeliness_checkbox, '#search_query_filter_case_type_foi-ir-timeliness'
        element :foi_non_trigger_checkbox, '#search_query_filter_sensitivity_non-trigger'
        element :foi_trigger_checkbox, '#search_query_filter_sensitivity_trigger'


        element :apply_filter_button, '.button[value="Apply filter"]'
      end
    end
  end
end
