module PageObjects
  module Pages
    module Cases
      class NewPage < SitePrism::Page
        set_url '/cases/new'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'


        element :date_received_day, '#case_received_responded_dd'
        element :date_received_month, '#case_date_responded_mm'
        element :date_received_year, '#case_date_responded_yyyy'

        element :submit_button, '.button'

        def fill_in_date_responded(date)
          date_received_day.set(date.day)
          date_received_month.set(date.month)
          date_received_year.set(date.year)
        end

      end
    end
  end
end
