module PageObjects
  module Sections
    module Cases
      class TypeComplaintFilterPanelSection < SitePrism::Section
        # The following checkboxes are invisible because ... govuk form
        # elements. Check for visibility on the panel section, not the
        # checkboxes
        element :complaint_standard_checkbox,
                "#search_query_filter_complaint_type_standard_complaint",
                visible: false
        element :complaint_ico_checkbox,
                "#search_query_filter_complaint_type_ico_complaint",
                visible: false
        element :complaint_litigation_checkbox,
                "#search_query_filter_complaint_type_litigation_complaint",
                visible: false
      end
    end
  end
end
