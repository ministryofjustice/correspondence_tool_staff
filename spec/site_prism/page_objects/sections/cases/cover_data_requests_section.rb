module PageObjects
  module Sections
    module Cases
      class CoverDataRequestsSection < SitePrism::Section
        element :section_heading, ".data-requests__title"
        element :heading, "thead tr"
        element :none, ".data-requests__none"

        sections :rows, "tbody tr" do
          element :location, "td:nth-child(1)"
          element :request_type, "td:nth-child(2)"
          element :date_requested, "td:nth-child(3)"
          element :pages, "td:nth-child(4)"
          element :date_received, "td:nth-child(5)"
          element :status, "td:nth-child(6)"
          element :edit, ".data-requests__edit"
          element :total_label, ".total-label"
          element :total_value, ".total-value"
        end
      end
    end
  end
end
