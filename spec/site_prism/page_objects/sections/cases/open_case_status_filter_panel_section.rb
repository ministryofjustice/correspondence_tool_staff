module PageObjects
  module Sections
    module Cases
      class OpenCaseStatusFilterPanelSection < SitePrism::Section
        element :hidden_checkbox, 'input[name="search_query[filter_status][]"]', visible: false

        element :unassigned_checkbox, '#search_query_filter_status_unassigned'

        element :apply_filter_button, '.button[value="Apply filter"]'
      end
    end
  end
end

