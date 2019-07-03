module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageDateReceived < PageObjects::Pages::Base

          set_url '/cases/offender_sars/new/date-received'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#offender_sar_subject_full_name'

          element :submit_button, '.button'

          # def set_received_date(received_date)
          #   date_received_day.set(received_date.day)
          #   date_received_month.set(received_date.month)
          #   date_received_year.set(received_date.year)
          # end
        end
      end
    end
  end
end
