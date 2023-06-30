module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageRequesterDetails < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/edit/requester_details"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :third_party_relationship, "#offender_sar_third_party_relationship"
          element :third_party_name, "#offender_sar_third_party_name"
          element :third_party_company_name, "#offender_sar_third_party_company_name"
          element :postal_address, "#offender_sar_postal_address"
          element :submit_button, ".button"

          def edit_third_party_name(value)
            third_party_name.set value
          end

          def choose_third_party_option(third_party_choice)
            if third_party_choice
              choose("offender_sar_third_party_true", visible: false)
            else
              choose("offender_sar_third_party_false", visible: false)
            end
          end
        end
      end
    end
  end
end
