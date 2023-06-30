module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageSentToSscl < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/edit/sent_to_sscl"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :sent_to_sscl_at_day, "#offender_sar_sent_to_sscl_at_dd"
          element :sent_to_sscl_at_month, "#offender_sar_sent_to_sscl_at_mm"
          element :sent_to_sscl_at_year, "#offender_sar_sent_to_sscl_at_yyyy"

          element :remove_button, ".sent-to-sscl-remove-date"
          element :remove_reason, "#offender_sar_remove_sent_to_sscl_reason"

          element :continue_button, ".button"

          def edit_sent_to_sscl_at(sent_date)
            sent_to_sscl_at_day.set sent_date.day
            sent_to_sscl_at_month.set sent_date.month
            sent_to_sscl_at_year.set sent_date.year
          end
        end
      end
    end
  end
end
