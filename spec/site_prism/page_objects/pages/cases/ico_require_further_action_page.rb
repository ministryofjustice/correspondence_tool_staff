module PageObjects
  module Pages
    module Cases
      class ICORequireFurtherActionPage < PageObjects::Pages::Base

        set_url '/cases/icos/{id}/require_further_action'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :external_deadline_day, '#ico_external_deadline_dd'
        element :external_deadline_month, '#ico_external_deadline_mm'
        element :external_deadline_year, '#ico_external_deadline_yyyy'

        element :internal_deadline_day, '#ico_internal_deadline_dd'
        element :internal_deadline_month, '#ico_internal_deadline_mm'
        element :internal_deadline_year, '#ico_internal_deadline_yyyy'

        element :continue_button, '.button'
        
        def fill_in_external_deadline(external_deadline)
          external_deadline_day.set(external_deadline.day)
          external_deadline_month.set(external_deadline.month)
          external_deadline_year.set(external_deadline.year)
        end

        def fill_in_internal_deadline(internal_deadline)
          internal_deadline_day.set(internal_deadline.day)
          internal_deadline_month.set(internal_deadline.month)
          internal_deadline_year.set(internal_deadline.year)
        end
      end
    end
  end
end
