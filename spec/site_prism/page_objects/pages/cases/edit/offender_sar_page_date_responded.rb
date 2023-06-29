module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageDateResponded < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/edit/date_responded"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :date_responded_day, "#offender_sar_date_responded_dd"
          element :date_responded_month, "#offender_sar_date_responded_mm"
          element :date_responded_year, "#offender_sar_date_responded_yyyy"

          element :continue_button, ".button"

          def edit_responded_date(received_date)
            date_responded_day.set received_date.day
            date_responded_month.set received_date.month
            date_responded_year.set received_date.year
          end
        end
      end
    end
  end
end
