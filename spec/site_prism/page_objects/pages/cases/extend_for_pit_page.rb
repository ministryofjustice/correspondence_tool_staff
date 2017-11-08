module PageObjects
  module Pages
    module Cases
      class ExtendForPITPage < SitePrism::Page
        set_url '/cases/{id}/extend_for_pit'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection,
                '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                '.page-heading'

        element :copy, '.action-copy'

        element :extension_date_day,   '#case_external_deadline_dd'
        element :extension_date_month, '#case_external_deadline_mm'
        element :extension_date_year,  '#case_external_deadline_yyyy'

        def fill_in_extension_date(date)
          extension_date_day.set(date.day)
          extension_date_month.set(date.month)
          extension_date_year.set(date.year)
        end

        element :reason_for_extending, '#case_reason_for_extending'
        element :submit_button, '.button'
      end
    end
  end
end
