module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageRequestedInfo < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/edit/requested_info"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :subject_full_name, "#offender_sar_subject_full_name"
          element :full_request, "#offender_sar_message"
          element :submit_button, ".button"

          def edit_message(message)
            full_request.set message
          end
        end
      end
    end
  end
end
