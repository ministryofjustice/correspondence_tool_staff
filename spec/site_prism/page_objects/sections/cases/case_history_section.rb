module PageObjects
  module Sections
    module Cases
      class CaseHistorySection < SitePrism::Section
        element :section_heading, "h2.request--heading"

        element :heading, "thead tr"
        elements :entries, "tbody tr"

        sections :rows, "tbody tr" do
          element :action_date, "td:nth-child(1)"
          element :user, "td:nth-child(2)"
          element :team, "td:nth-child(3)"
          section :details, "td:nth-child(4)" do
            element :event, "strong"
          end
        end

        def row_for_event(event_name)
          rows.find do |row|
            row.details.event.text == event_name
          end
        end
      end
    end
  end
end
