module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageDateReceived < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/edit/date_received"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :subject_full_name, "#offender_sar_subject_full_name"
          element :date_received_day, "#offender_sar_received_date_dd"
          element :date_received_month, "#offender_sar_received_date_mm"
          element :date_received_year, "#offender_sar_received_date_yyyy"

          element :submit_button, ".button"

          def edit_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end
        end
      end
    end
  end
end
