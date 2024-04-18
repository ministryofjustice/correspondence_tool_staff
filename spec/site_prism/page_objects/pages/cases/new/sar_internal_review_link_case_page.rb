module PageObjects
  module Pages
    module Cases
      module New
        class SARInternalReviewLinkCasePage < PageObjects::Pages::Base
          set_url "/cases/sar_internal_review/new"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :primary_heading, "#content > div:nth-child(2) > div > header > h1 > span.page-heading--primary"

          element :original_case_number, "#sar_internal_review_original_case_number"

          element :submit_button, ".button"

          def fill_in_original_case_number(case_number)
            original_case_number.set(case_number)
          end
        end
      end
    end
  end
end
