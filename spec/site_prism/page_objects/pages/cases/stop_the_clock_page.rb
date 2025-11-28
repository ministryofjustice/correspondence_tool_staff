module PageObjects
  module Pages
    module Cases
      class StopTheClockPage < PageObjects::Pages::Base
        set_url "/cases/{id}/stop_the_clocks/new"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection,
                ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                ".page-heading"

        element :copy, ".action-copy"

        section :categories_list, ".stop_the_clock__categories-list > fieldset" do
          element :multiple_choice, ".multiple-choice"
        end

        element :stop_the_clock_reason, "#case_stop_the_clock_reason"

        element :stop_the_clock_date_day,   "#case_stop_the_clock_date_dd"
        element :stop_the_clock_date_month, "#case_stop_the_clock_date_mm"
        element :stop_the_clock_date_year,  "#case_stop_the_clock_date_yyyy"

        element :submit_button, ".button"
        element :cancel, "a.acts-like-button"


        def fill_in_stop_the_clock_date(date)
          stop_the_clock_date_day.set(date.day)
          stop_the_clock_date_month.set(date.month)
          stop_the_clock_date_year.set(date.year)
        end
      end
    end
  end
end
