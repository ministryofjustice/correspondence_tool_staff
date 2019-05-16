module PageObjects
  module Pages
    module Stats
      class IndexPage < PageObjects::Pages::Base
        set_url '/stats'

        section(
          :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection,
          '.global-nav'
        )

        section(
          :page_heading,
          PageObjects::Sections::PageHeadingSection,
          '.page-heading'
        )

        element :report_caption, 'table caption'

        %i[foi sar closed_cases].each_with_index do |performance_type, i|
          section performance_type, "section:nth-of-type(#{i + 1})" do
            element :type_name, 'h2'
            sections :reports, 'ul.report-list li' do
              element :name, 'h3'
              element :description, '.report-description'
              element :report_period, '.report-period'
              element :download, '.report-list-download'
              element :download_link, '.report-list-download a'
            end
          end
        end

        element :custom_reports, '.button'
      end
    end
  end
end


