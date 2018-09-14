module PageObjects
  module Pages
    module Cases
      module New
        class ICOPage < PageObjects::Pages::Base
          set_url '/cases/new/ico'

          section :errors, PageObjects::Sections::Errors, '.error-summary'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          section :form,
                  PageObjects::Sections::Cases::ICO::FormSection,
                  'form#new_case_ico'
        end
      end
    end
  end
end
