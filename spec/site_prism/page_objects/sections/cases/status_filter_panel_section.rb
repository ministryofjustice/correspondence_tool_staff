module PageObjects
  module Sections
    module Cases
      class StatusFilterPanelSection < SitePrism::Section
        element :open_checkbox, '#search_query_filter_status_open'
        element :closed_checkbox, '#search_query_filter_status_closed'
        element :apply_filter_button, '.button[value="Apply filter"]'
      end
    end
  end
end

