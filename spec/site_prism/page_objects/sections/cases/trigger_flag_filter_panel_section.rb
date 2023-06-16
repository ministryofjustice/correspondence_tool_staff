module PageObjects
  module Sections
    module Cases
      class TriggerFlagFilterPanelSection < SitePrism::Section
        # The following checkboxes are invisible because ... govuk form
        # elements. Check for visibility on the panel section, not the
        # checkboxes
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
