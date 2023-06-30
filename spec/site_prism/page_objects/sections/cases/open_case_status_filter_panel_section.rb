module PageObjects
  module Sections
    module Cases
      class OpenCaseStatusFilterPanelSection < SitePrism::Section
        element :hidden_checkbox,
                'input[name="search_query[filter_status][]"]',
                visible: false

        element :unassigned_checkbox,
                "#search_query_filter_open_case_status_unassigned",
                visible: false

        element :responded_checkbox,
                "#search_query_filter_open_case_status_responded",
                visible: false

        element :open_checkbox,
                "#search_query_filter_status_open",
                visible: false

        element :closed_checkbox,
                "#search_query_filter_status_closed",
                visible: false
      end
    end
  end
end
