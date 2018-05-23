module PageObjects
  module Sections
    module Cases
      class AssignedToFilterPanelSection < SitePrism::Section
        element :business_unit_search_term, 'input#search_query_business_unit_name_filter'
        element :main_responding_team_checkbox, :xpath, '//div[@class="js-all-business-units scrolling-details"]//label[contains(.,"Main responding_team")]'

        element :apply_filter_button, '.button[value="Apply filter"]'

        def checkbox_for(business_unit)
          unless business_unit.is_a? BusinessUnit
            business_unit = BusinessUnit
                              .where('name LIKE ?', "%#{business_unit}%")
                              .singular_or_nil
          end
          find "#search_query_filter_assigned_to_ids_#{business_unit.id}",
               visible: false
        end
      end
    end
  end
end
