module PageObjects
  module Sections
    module Cases
      class OpenCaseStatusFilterPanelSection < SitePrism::Section
        element :hidden_checkbox,
                'input[name="search_query[filter_status][]"]',
                visible: false

        element :unassigned_checkbox,
                '#search_query_filter_open_case_status_unassigned',
                visible: false

        element :responded_checkbox,
                '#search_query_filter_open_case_status_responded',
                visible: false

        element :apply_filter_button, '.button[value="Apply filter"]'
      end
    end
  end
end

