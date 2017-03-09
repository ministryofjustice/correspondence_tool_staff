module PageObjects
  module Pages
    module Cases
      class ClosePage < SitePrism::Page
        set_url '/cases/{id}'

        element :date_responded_day, '#case_date_responded_dd'
        element :date_responded_month, '#case_date_responded_mm'
        element :date_responded_year, '#case_date_responded_yyyy'

        element :outcome_radio_button_fully_granted, 'label[for="case_outcome_name_granted_in_full"]'
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
