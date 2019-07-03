module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageRequesterDetails < PageObjects::Pages::Base

          set_url '/cases/offender_sars/new/requester-details'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#offender_sar_subject_full_name'

          element :submit_button, '.button'
        end
      end
    end
  end
end
