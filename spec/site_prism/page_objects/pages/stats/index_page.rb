module PageObjects
  module Pages
    module Stats
      class IndexPage < PageObjects::Pages::Base
        set_url '/stats'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :report_caption, 'table caption'

        sections :reports, '.stats-report tbody tr' do
          element :name, 'th'
          element :action_link, 'td a'
        end
      end
    end
  end
end


