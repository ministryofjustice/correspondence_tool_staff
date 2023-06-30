module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageLinkSarCase < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/new"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :original_case_number, "#offender_sar_complaint_original_case_number"

          element :submit_button, ".button"

          def fill_in_original_case_number(case_number)
            original_case_number.set case_number
          end
        end
      end
    end
  end
end
