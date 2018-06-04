module PageObjects
  module Pages
    module Cases
      class RespondPage < SitePrism::Page
        set_url '/cases/{id}/respond'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :reminders,    '.reminders'
        element :alert,        '.notice'
        element :mark_as_sent_button, 'a.button'
        element :back_link,  'a.button-secondary'

        element :submit_button, '.button'

        def fill_in_date_responded(date)
          date_responded_day.set(date.day)
          date_responded_month.set(date.month)
          date_responded_year.set(date.year)
        end

      end
    end
  end
end
