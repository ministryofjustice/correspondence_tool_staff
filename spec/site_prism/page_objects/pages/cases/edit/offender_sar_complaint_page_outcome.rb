module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARComplaintPageOutcome < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/{id}/edit/outcome"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :submit_button, ".button"

          def choose_outcome(outcome_choice)
            if outcome_choice.present?
              choose("offender_sar_complaint_outcome_id_#{outcome_choice.id}", visible: false)
            end
          end
        end
      end
    end
  end
end
