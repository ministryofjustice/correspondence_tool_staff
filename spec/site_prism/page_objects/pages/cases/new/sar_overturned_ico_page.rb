module PageObjects
  module Pages
    module Cases
      module New
        class SarOverturnedIcoPage < PageObjects::Pages::Base
          set_url '/cases/overturned_ico_sar/{id}/new'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          section :form,
                  PageObjects::Sections::Cases::OverturnedICO::NewFormSection,
                  'form#overturned_sar, form#overturned_foi'
        end
      end
    end
  end
end
