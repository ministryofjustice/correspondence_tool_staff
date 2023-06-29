module PageObjects
  module Pages
    module Cases
      class ExtendSARDeadlinePage < SitePrism::Page
        set_url "/cases/{id}/sar_extensions/new"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection,
                ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                ".page-heading"

        element :copy, ".action-copy"

        element :extension_period_1_calendar_month, "#case_extension_period_1"
        element :extension_period_2_calendar_months, "#case_extension_period_2"
        element :reason_for_extending, "#case_reason_for_extending"

        element :submit_button, ".button"

        def set_reason_for_extending(message)
          reason_for_extending.set(message)
        end
      end
    end
  end
end
