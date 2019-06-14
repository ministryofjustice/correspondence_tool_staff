module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageRequesterDetails < PageObjects::Pages::Base

          set_url '/cases/new/offender/requester-details'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :requester_full_name, '#offender_sar_case_form_name'

          element :third_party_relationship, '#offender_sar_case_form_third_party_relationship'

          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build :offender_sar_case, params

            if kase.third_party?
              choose_third_party true
              requester_full_name.set kase.name
              third_party_relationship.set kase.third_party_relationship
            else
              choose_third_party false
            end

            if kase.send_by_email?
              choose_reply_method 'send_by_email'
              email.set kase.email
            elsif kase.send_by_post?
              choose_reply_method 'send_by_post'
              postal_address.set kase.postal_address
            end
            #choose('offender_sar_case_form_third_party_true', visible: false)
            #fill_in :offender_sar_case_form_name, with: "John Ali"
            #fill_in :offender_sar_case_form_third_party_relationship, with: "Father"

            #choose('offender_sar_case_form_reply_method_send_by_email', visible: false)
            #fill_in :offender_sar_case_form_email, with: "bob@example.com"

            #choose('offender_sar_case_form_reply_method_send_by_post', visible: false)
            #fill_in :offender_sar_case_form_postal_address, with: "66A Eltham Road, Nottingham, NG2 5AA"
            #click_on "Continue"
          end
        end
      end
    end
  end
end
