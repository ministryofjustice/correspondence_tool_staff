module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageDateReceived < PageObjects::Pages::Base

          set_url '/cases/offender_sar_complaints/date-received'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#offender_sar_complaint_subject_full_name'
          element :date_received_day, '#offender_sar_complaint_received_date_dd'
          element :date_received_month, '#offender_sar_complaint_received_date_mm'
          element :date_received_year, '#offender_sar_complaint_received_date_yyyy'

          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build_stubbed :offender_sar_complaint, params

            set_received_date(kase.received_date)
          end

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
