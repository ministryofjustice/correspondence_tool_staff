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

          element :subject_full_name, '#offender_sar_subject_full_name'
          element :email_address, '#offender_sar_email'
          element :postal_address, '#offender_sar_postal_address'
          element :name, 'offender_sar_name'
          element :third_party_relationship, '#offender_sar_third_party_relationship'

          element :submit_button, '.button'

          def edit_email(value)
            email_address.set value
          end
        end
      end
    end
  end
end
