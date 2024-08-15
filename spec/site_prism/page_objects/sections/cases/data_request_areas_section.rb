module PageObjects
  module Sections
    module Cases
      class DataRequestAreasSection < SitePrism::Section
        element :section_heading, ".data-request_areas___title"
        element :heading, "thead tr"
        element :none, ".data-request_areas__none"

        sections :rows, "tbody tr" do
          element :data_area, "td:nth-child(1)"
          element :location, "td:nth-child(2)"
          element :num_of_data_types, "td:nth-child(3)"
          element :date_requested, "td:nth-child(4)"
          element :pages, "td:nth-child(5)"
          element :date_received, "td:nth-child(6)"
          element :status, "td:nth-child(7)"
          element :show, ".data-request_areas__show"
          element :total_label, "td:nth-child(1)"
          element :total_value, "td:nth-child(2)"
        end
      end
    end
  end
end
