module PageObjects
  module Sections
    module Cases
      class AssignedToFilterPanelSection < SitePrism::Section
        element :business_unit_search_term, 'input#search_query_business_unit_name_filter'
        element :main_responding_team_checkbox, :xpath, '//div[@class="js-all-business-units scrolling-details"]//label[contains(.,"Main responding_team")]'

        element :apply_filter_button, '.button[value="Apply filter"]'
      end
    end
  end
end
