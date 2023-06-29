module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageMoveCaseBack < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/move_case_back"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :extra_comment, "#extra_comment"

          element :continue_button, ".button"

          def fill_in_reason(reason)
            extra_comment.set(reason)
          end
        end
      end
    end
  end
end
