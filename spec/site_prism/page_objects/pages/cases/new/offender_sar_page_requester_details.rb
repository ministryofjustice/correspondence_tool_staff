module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageRequesterDetails < PageObjects::Pages::Base

          set_url '/cases/offender_sars/requester-details'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :third_party_relationship, '#offender_sar_third_party_relationship'
          element :third_party_name, '#offender_sar_third_party_name'
          element :third_party_company_name, '#offender_sar_third_party_company_name'
          element :email_address, '#offender_sar_email'
          element :postal_address, '#offender_sar_postal_address'
          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build :offender_sar_case, params

            if kase.third_party?
              choose('offender_sar_third_party_true', visible: false)
              requester_full_name.set kase.name
              third_party_relationship.set kase.third_party_relationship
              third_party_name.set kase.third_party_name
              third_party_company_name.set kase.third_party_company_name
            else
              choose('offender_sar_third_party_false', visible: false)
            end

            if kase.send_by_email?
              choose('offender_sar_reply_method_send_by_email', visible: false)
              email_address.set kase.email
            elsif kase.send_by_post?
              choose('offender_sar_reply_method_send_by_post', visible: false)
              postal_address.set kase.postal_address
            end
          end
        end
      end
    end
  end
end
