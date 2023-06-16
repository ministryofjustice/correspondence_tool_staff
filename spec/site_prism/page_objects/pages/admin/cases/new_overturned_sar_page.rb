module PageObjects
  module Pages
    module Admin
      module Cases
        class NewOverturnedSARPage < PageObjects::Pages::Base
          set_url "/admin/cases/new/overturned_sar"

          sections :notices, ".notice-summary" do
            element :heading, ".notice-summary-heading"
          end

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :date_received_day, "#case_overturned_sar_received_date_dd"
          element :date_received_month, "#case_overturned_sar_received_date_mm"
          element :date_received_year, "#case_overturned_sar_received_date_yyyy"

          element :external_deadline_day, "#case_overturned_sar_external_deadline_dd"
          element :external_deadline_month, "#case_overturned_sar_external_deadline_mm"
          element :external_deadline_year, "#case_overturned_sar_external_deadline_yyyy"

          element :target_state, "#case_overturned_sar_target_state"

          element :flag_for_disclosure_specialists,
                  "#case_overturned_sar_flagged_for_disclosure_specialist_clearance"

          element :submit_button, ".button"

          def set_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end
        end
      end
    end
  end
end
