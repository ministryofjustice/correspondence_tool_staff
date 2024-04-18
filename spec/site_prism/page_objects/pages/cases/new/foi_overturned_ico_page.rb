module PageObjects
  module Pages
    module Cases
      module New
        class FOIOverturnedICOPage < PageObjects::Pages::Base
          set_url "/cases/overturned_ico_fois/new/{id}"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          section :form,
                  PageObjects::Sections::Cases::OverturnedICO::NewFormSection,
                  "form#new_overturned_sar, form#new_overturned_foi"
        end
      end
    end
  end
end
