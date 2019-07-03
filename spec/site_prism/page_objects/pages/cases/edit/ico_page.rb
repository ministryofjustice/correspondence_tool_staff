module PageObjects
  module Pages
    module Cases
      module Edit
        class ICOPage < PageObjects::Pages::Base
          set_url '/cases/ico/{id}/edit'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          section :form,
                  PageObjects::Sections::Cases::ICO::FormSection,
                  'form#edit_ico'

          element :cancel, 'a'

        end
      end
    end
  end
end
