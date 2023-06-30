module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARComplaintPageCosts < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/{id}/edit/costs"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :settlement_cost, "#offender_sar_complaint_settlement_cost"
          element :total_cost, "#offender_sar_complaint_total_cost"

          element :submit_button, ".button"

          def fill_in_costs(settlement_cost_value, total_cost_value)
            settlement_cost.set settlement_cost_value
            total_cost.set total_cost_value
          end
        end
      end
    end
  end
end
