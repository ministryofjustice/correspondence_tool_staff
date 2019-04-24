module PageObjects
  module Pages
    module Cases
      class FilterClosedCasesPage < SitePrism::Page
        set_url '/cases/closed/filter'

        section :primary_navigation,
        PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
        PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :last_month_link, 'a:contains("Last month")'

        section :period_start, '.period-start' do
          element :day, '#report_period_start_dd'
          element :month, '#report_period_start_mm'
          element :year, '#report_period_start_yyyy'
        end

        section :period_end, '.period-end' do
          element :day, '#report_period_end_dd'
          element :month, '#report_period_end_mm'
          element :year, '#report_period_end_yyyy'
        end

        element :submit_button, '.button'

        # @todo (Mohammed Seedat): consider DRY fill_in_ code

        def fill_in_period_start(date)
          period_start.day.set(date.day)
          period_start.month.set(date.month)
          period_start.year.set(date.year)
        end

        def fill_in_period_end(date)
          period_end.day.set(date.day)
          period_end.month.set(date.month)
          period_end.year.set(date.year)
        end

        def fill_in_form(period_start_date, period_end_date)
          fill_in_period_start(period_start_date)
          fill_in_period_end(period_end_date)
        end
      end
    end
  end
end
