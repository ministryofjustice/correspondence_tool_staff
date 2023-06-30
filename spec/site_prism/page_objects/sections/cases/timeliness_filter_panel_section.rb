module PageObjects
  module Sections
    module Cases
      class TimelinessFilterPanelSection < SitePrism::Section
        element :hidden_checkbox, 'input[name="search_query[filter_status][]"]', visible: false

        # The following checkboxes are invisible because ... govuk form
        # elements. Check for visibility on the panel section, not the
        # checkboxes
        element :in_time_checkbox,
                "#search_query_filter_timeliness_in_time",
                visible: false
        element :late_checkbox,
                "#search_query_filter_timeliness_late",
                visible: false
      end
    end
  end
end
