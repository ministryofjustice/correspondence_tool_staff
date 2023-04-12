module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageRequestedInfo < PageObjects::Pages::Base

          set_url '/cases/offender_sars/requested-info'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#offender_sar_subject_full_name'
          element :full_request, '#offender_sar_message'
          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build_stubbed :offender_sar_case, params

            full_request.set kase.message
          end
        end
      end
    end
  end
end
