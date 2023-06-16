module PageObjects
  module Sections
    module Cases
      class CaseStatusSection < SitePrism::Section
        section :details, ".case-status__info.case-status__info--details" do
          element :copy_label, ".status .case-status__heading"
          element :copy,
                  ".status .case-status__data--large"
          element :who_its_with_label,
                  ".who_its_with .case-status__heading"
          element :who_its_with,
                  ".who_its_with .case-status__data"
          element :ico_ref_number_label,
                  ".ico-reference .case-status__heading"
          element :ico_ref_number,
                  ".ico-reference .case-status__data"

          section :page_counts, ".case-status__group.page-counts" do
            element :received_label, ".column-one-third:nth-child(1) .case-status__heading"
            element :received_number, ".column-one-third:nth-child(1) .case-status__date-value"
            element :exempt_label, ".column-one-third:nth-child(2) .case-status__heading"
            element :exempt_number, ".column-one-third:nth-child(2) .case-status__date-value"
            element :dispatched_label, ".column-one-third:nth-child(3) .case-status__heading"
            element :dispatched_number, ".column-one-third:nth-child(3) .case-status__date-value"
          end
        end

        section :deadlines, ".case-status__info.case-status__info--deadlines" do
          element :draft_label, ".draft .case-status__date-title"
          element :draft, ".draft .case-status__date-value"
          element :final_label, ".external .case-status__date-title"
          element :final, ".external .case-status__date-value"
        end
      end
    end
  end
end
