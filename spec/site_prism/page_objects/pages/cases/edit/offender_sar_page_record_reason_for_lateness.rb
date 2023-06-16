module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageRecordReasonForLateness < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/record_reason_for_lateness"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :submit_button, ".button"
          element :note_for_reason, "#offender_sar_reason_for_lateness_note"

          def choose_reason(reason_choice, reason_note: nil)
            if reason_choice.present?
              choose("offender_sar_reason_for_lateness_id_#{reason_choice.id}", visible: false)
            end
            if reason_choice.code == "other" && reason_note.present?
              note_for_reason.set(reason_note)
            end
          end
        end
      end
    end
  end
end
