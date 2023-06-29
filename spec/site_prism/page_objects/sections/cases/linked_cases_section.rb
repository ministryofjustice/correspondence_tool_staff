module PageObjects
  module Sections
    module Cases
      class LinkedCasesSection < SitePrism::Section
        element :section_heading, ".request--heading"

        sections :linked_records, "table tbody tr" do
          element :link, "td:nth-child(1) a"
          element :case_type, "td:nth-child(2)"
          element :request, "td:nth-child(3)"
          element :remove_link, "td:nth-child(4) a"
          element :no_linked_cases, 'td[colspan="4"]'
        end

        element :action_link, "#action--link-a-case"
      end
    end
  end
end
