module PageObjects
  module Pages
    module Admin
      module Cases
        class NewICOPage < PageObjects::Pages::Base
          set_url "/admin/cases/new/ico"

          sections :notices, ".notice-summary" do
            element :heading, ".notice-summary-heading"
          end

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :ico_reference_number, "#case_ico_ico_reference_number"
          element :ico_officer_name, "#case_ico_ico_officer_name"

          element :original_case_type_foi, "#case_ico_type_caseicofoi"
          element :original_case_type_sar, "#case_ico_type_caseicosar"

          element :date_received_day, "#case_ico_received_date_dd"
          element :date_received_month, "#case_ico_received_date_mm"
          element :date_received_year, "#case_ico_received_date_yyyy"

          element :external_deadline_day, "#case_ico_external_deadline_dd"
          element :external_deadline_month, "#case_ico_external_deadline_mm"
          element :external_deadline_year, "#case_ico_external_deadline_yyyy"

          element :case_details, "#case_ico_message"

          element :repsonding_team, "#case_ico_responding_team"

          element :target_state, "#case_ico_target_state"

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
