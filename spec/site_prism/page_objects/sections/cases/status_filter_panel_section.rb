module PageObjects
  module Sections
    module Cases
      class StatusFilterPanelSection < SitePrism::Section
        element :hidden_checkbox, 'input[name="search_query[filter_status][]"]', visible: false

        # The following checkboxes are invisible because ... govuk form
        # elements. Check for visibility on the panel section, not the
        # checkboxes
        element :open_checkbox, '#search_query_filter_status_open', visible: false
        element :closed_checkbox, '#search_query_filter_status_closed', visible: false

        element :apply_filter_button, '.button-secondary[value="Filter"]'
      end
    end
  end
end
