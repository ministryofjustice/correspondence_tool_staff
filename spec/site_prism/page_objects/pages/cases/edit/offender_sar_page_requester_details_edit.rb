module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageRequesterDetails < PageObjects::Pages::Base

          set_url '/cases/offender_sars/{id}/edit/requester_details'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :third_party_relationship, '#offender_sar_third_party_relationship'
          element :third_party_name, '#offender_sar_third_party_name'
          element :third_party_company_name, '#offender_sar_third_party_company_name'
          element :postal_address, '#offender_sar_postal_address'
          element :submit_button, '.button'

          def edit_third_party_name(value)
            third_party_name.set value
          end
        end
      end
    end
  end
end
