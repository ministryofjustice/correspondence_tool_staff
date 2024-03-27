module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageReasonRejected < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/edit/reason_rejected"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :rejected_reason, "#rejected_reasons"
          element :submit_button, ".button"

          def choose_rejected_reason(choice)
            make_check_box_choice("offender_sar_rejected_reasons_#{choice}")
          end
        end
      end
    end
  end
end
