module PageObjects
  module Pages
    module Cases
      module New
        class OverturnedICOPage < PageObjects::Pages::Base
          set_url '/cases/{id}/new_overturned_ico'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          section :form,
                  PageObjects::Sections::Cases::OverturnedICO::NewFormSection,
                  'form#new_case_overturned_sar, form#new_case_overturned_foi'
        end
      end
    end
  end
end
