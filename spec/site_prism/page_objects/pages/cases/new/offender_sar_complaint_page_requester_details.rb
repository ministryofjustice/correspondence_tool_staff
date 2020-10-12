module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageRequesterDetails < PageObjects::Pages::Base

          set_url '/cases/offender_sar_complaints/requester-details'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :third_party_relationship, '#offender_sar_complaint_third_party_relationship'
          element :third_party_name, '#offender_sar_complaint_third_party_name'
          element :third_party_company_name, '#offender_sar_complaint_third_party_company_name'
          element :postal_address, '#offender_sar_complaint_postal_address'
          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build :offender_sar_complaint, params

            if kase.third_party?
              choose('offender_sar_complaint_third_party_true', visible: false)
              third_party_relationship.set kase.third_party_relationship
              third_party_name.set kase.third_party_name
              third_party_company_name.set kase.third_party_company_name
              postal_address.set kase.postal_address
            else
              choose('offender_sar_complaint_third_party_false', visible: false)
            end
          end
        end
      end
    end
  end
end
