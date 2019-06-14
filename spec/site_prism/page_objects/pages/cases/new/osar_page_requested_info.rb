module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageRequestedInfo < PageObjects::Pages::Base

          set_url '/cases/new/offender/requested-info'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :full_request, '#offender_sar_case_form_message'

          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build :offender_sar_case, params

            full_request.set kase.message

            #fill_in :offender_sar_case_form_message, with: "Offender Sar Case, urgent, needs to be looked at, please! like now? while we're young, today!"
          end
        end
      end
    end
  end
end
