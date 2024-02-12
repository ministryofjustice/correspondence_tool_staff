module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARInformationReceived < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/information_received"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :information_received, "#information_received"

          element :continue_button, ".button"

          def choose_information_received_button(choice)
            make_radio_button_choice("offender_sar_information_received_#{choice}")
          end
        end
      end
    end
  end
end
