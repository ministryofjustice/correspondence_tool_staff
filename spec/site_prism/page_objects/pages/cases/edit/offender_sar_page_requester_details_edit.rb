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
          element :email_address, '#offender_sar_email'
          element :postal_address, '#offender_sar_postal_address'
          element :submit_button, '.button'

          def edit_email(value)
            choose('offender_sar_reply_method_send_by_email', visible: false)
            email_address.set value
          end
        end
      end
    end
  end
end
