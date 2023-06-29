module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageConfirmCase < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/confirm-offender-sar"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :yes, "#offender_sar_complaint_original_case_number"

          element :submit_button, ".button"

          sections :back_links, ".govuk-back-link" do
          end

          def confirm_yes
            choose("offender_sar_complaint_original_case_number_yes", visible: false)
          end

          def find_first_back_link
            find(".govuk-back-link", match: :first)
          end
        end
      end
    end
  end
end
