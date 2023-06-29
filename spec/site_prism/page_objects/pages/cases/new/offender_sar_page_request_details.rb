module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageRequestDetails < PageObjects::Pages::Base
          set_url "/cases/offender_sars/request-details"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :request_dated_day, "#offender_sar_request_dated_dd"
          element :request_dated_month, "#offender_sar_request_dated_mm"
          element :request_dated_year, "#offender_sar_request_dated_yyyy"
          element :requester_reference, "#offender_sar_requester_reference"

          def fill_in_case_details(params = {})
            kase = FactoryBot.build_stubbed :offender_sar_case, params

            request_dated_day.set(kase.request_dated_dd)
            request_dated_month.set(kase.request_dated_mm)
            request_dated_year.set(kase.request_dated_yyyy)
            requester_reference.set(kase.requester_reference)
          end
        end
      end
    end
  end
end
