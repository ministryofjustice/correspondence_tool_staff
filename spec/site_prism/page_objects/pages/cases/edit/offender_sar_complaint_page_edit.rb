module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARComplaintPageEdit < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/{id}"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"
        end
      end
    end
  end
end
