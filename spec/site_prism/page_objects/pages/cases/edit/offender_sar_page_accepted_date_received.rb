module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARAcceptedDateReceived < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/accepted_date_received"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :date_received, "#date_received"

          element :continue_button, ".button"

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
