module PageObjects
  module Pages
    module Cases
      class RespondPage < SitePrism::Page
        set_url '/cases/{correspondence_type}/{id}/respond'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :foi_task_reminder, '.reminders'

        element :date_responded_day, :case_form_element, 'date_responded_dd'
        element :date_responded_month, :case_form_element, 'date_responded_mm'
        element :date_responded_year, :case_form_element, 'date_responded_yyyy'

        element :back_link,  'a.acts-like-button'
        element :submit_button, '.button'

        element :today_button, '#sar_internal_review_date_responded > fieldset > div > a'

        def fill_in_date_responded(date)
          date_responded_day.set(date.day)
          date_responded_month.set(date.month)
          date_responded_year.set(date.year)
        end

      end
    end
  end
end
