module PageObjects
  module Pages
    module Stats
      class CustomPage < PageObjects::Pages::Base
        set_url '/stats/custom'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :success_message, '.notice-summary' do
          element :download_link, 'a'
        end

        section :report_types, '.report-types' do
          elements :report, 'label'
        end

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

        def choose_type_of_report(report_id)
          make_radio_button_choice("report_report_type_id_#{report_id}")
        end

        def fill_in_form(report_id, period_start_date, period_end_date )
          choose_type_of_report(report_id)
          fill_in_period_start(period_start_date)
          fill_in_period_end(period_end_date)
        end
      end
    end
  end
end


