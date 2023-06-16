module PageObjects
  module Sections
    module Cases
      class TypeFilterPanelSection < SitePrism::Section
        # The following checkboxes are invisible because ... govuk form
        # elements. Check for visibility on the panel section, not the
        # checkboxes
        element :foi_standard_checkbox,
                "#search_query_filter_case_type_foi-standard",
                visible: false
        element :foi_ir_compliance_checkbox,
                "#search_query_filter_case_type_foi-ir-compliance",
                visible: false
        element :foi_ir_timeliness_checkbox,
                "#search_query_filter_case_type_foi-ir-timeliness",
                visible: false
        element :sar_non_offender_checkbox,
                "#search_query_filter_case_type_sar-non-offender",
                visible: false
        element :overturned_ico_checkbox,
                "#search_query_filter_case_type_overturned-ico",
                visible: false
        element :non_trigger_checkbox,
                "#search_query_filter_sensitivity_non-trigger",
                visible: false
        element :trigger_checkbox,
                "#search_query_filter_sensitivity_trigger",
                visible: false
      end
    end
  end
end
