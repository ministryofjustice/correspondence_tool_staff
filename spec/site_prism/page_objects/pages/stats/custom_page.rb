module PageObjects
  module Pages
    module Stats
      class CustomPage < PageObjects::Pages::Base
        set_url '/stats/custom'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

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

      end
    end
  end
end


