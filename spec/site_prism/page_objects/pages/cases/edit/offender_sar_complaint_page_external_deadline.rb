module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARComplaintPageExternalDeadline < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/{id}/edit/set-deadline"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :external_deadline_day, "#offender_sar_complaint_external_deadline_dd"
          element :external_deadline_month, "#offender_sar_complaint_external_deadline_mm"
          element :external_deadline_year, "#offender_sar_complaint_external_deadline_yyyy"

          element :continue_button, ".button"

          def edit_external_deadline(external_deadline)
            external_deadline_day.set(external_deadline.day)
            external_deadline_month.set(external_deadline.month)
            external_deadline_year.set(external_deadline.year)
          end
        end
      end
    end
  end
end
