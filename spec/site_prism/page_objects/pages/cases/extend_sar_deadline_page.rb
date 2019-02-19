module PageObjects
  module Pages
    module Cases
      class ExtendSARDeadlinePage < SitePrism::Page
        set_url '/cases/{id}/extend_sar_deadline'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection,
          '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection,
          '.page-heading'

        element :copy, '.action-copy'

        element :extension_period_30_days,  '#case_extension_period_30'
        element :extension_period_60_days,  '#case_extension_period_60'
        element :reason_for_extending,      '#case_reason_for_extending'

        element :submit_button, '.button'

        def set_reason_for_extending(message)
          reason_for_extending.set(message)
        end
      end
    end
  end
end
