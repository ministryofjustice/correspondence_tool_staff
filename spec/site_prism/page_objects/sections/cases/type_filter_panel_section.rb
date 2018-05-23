module PageObjects
  module Sections
    module Cases
      class TypeFilterPanelSection < SitePrism::Section
        # The following checkboxes are invisible because ... govuk form
        # elements. Check for visibility on the panel section, not the
        # checkboxes
        element :foi_standard_checkbox,
                '#search_query_filter_case_type_foi-standard',
                visible: false
        element :foi_ir_compliance_checkbox,
                '#search_query_filter_case_type_foi-ir-compliance',
                visible: false
        element :foi_ir_timeliness_checkbox,
                '#search_query_filter_case_type_foi-ir-timeliness',
                visible: false
        element :foi_non_trigger_checkbox,
                '#search_query_filter_sensitivity_non-trigger',
                visible: false
        element :foi_trigger_checkbox,
                '#search_query_filter_sensitivity_trigger',
                visible: false


        element :apply_filter_button, '.button[value="Apply filter"]'
      end
    end
  end
end
