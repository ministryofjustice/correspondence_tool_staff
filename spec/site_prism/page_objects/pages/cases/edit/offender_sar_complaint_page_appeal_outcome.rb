module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARComplaintPageAppealOutcome < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/{id}/edit/appeal_outcome"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :submit_button, ".button"

          def choose_appeal_outcome(appeal_outcome_choice)
            if appeal_outcome_choice.present?
              choose("offender_sar_complaint_appeal_outcome_id_#{appeal_outcome_choice.id}", visible: false)
            end
          end
        end
      end
    end
  end
end
