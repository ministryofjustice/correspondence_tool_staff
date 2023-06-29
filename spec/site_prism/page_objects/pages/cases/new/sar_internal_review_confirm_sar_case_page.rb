module PageObjects
  module Pages
    module Cases
      module New
        class SarInternalReviewConfirmSarCasePage < PageObjects::Pages::Base
          set_url "/cases/sar_internal_review/confirm-sar"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :back_link, "a[href='/cases/sar_internal_review/link-sar-case']:first-child"

          element :original_case_number, "#sar_internal_review_original_case_number_yes", visible: false

          element :submit_button, ".button"
        end
      end
    end
  end
end
