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

        element :date_responded_day, '#case_sar_date_responded_dd'
        element :date_responded_month, '#case_sar_date_responded_mm'
        element :date_responded_year, '#case_sar_date_responded_yyyy'

        section :missing_info, '.missing-info' do
          element :yes, 'label[for="case_sar_missing_info_yes"]'
          element :no, 'label[for="case_sar_missing_info_no"]'
        end

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
