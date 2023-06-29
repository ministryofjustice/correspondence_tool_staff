module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageExternalDeadline < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/set-deadline"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :external_deadline_day, "#offender_sar_complaint_external_deadline_dd"
          element :external_deadline_month, "#offender_sar_complaint_external_deadline_mm"
          element :external_deadline_year, "#offender_sar_complaint_external_deadline_yyyy"

          element :submit_button, ".button"

          def fill_in_case_details(external_deadline: nil)
            if external_deadline.present?
              set_external_deadline(external_deadline)
            end
          end

          def set_external_deadline(external_deadline)
            external_deadline_day.set(external_deadline.day)
            external_deadline_month.set(external_deadline.month)
            external_deadline_year.set(external_deadline.year)
          end
        end
      end
    end
  end
end
