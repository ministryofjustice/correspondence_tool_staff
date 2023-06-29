module PageObjects
  module Pages
    module Cases
      class EditPage < PageObjects::Pages::Base
        # This page is just a version of the new page.

        set_url "/cases/{correspondence_type}/{id}/edit"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :foi_detail,
                PageObjects::Sections::Cases::FoiEditDetailsSection, "body"

        section :sar_detail,
                PageObjects::Sections::Cases::SarEditDetailsSection, "body"

        element :submit_button, ".button"
        element :cancel, "a"
      end
    end
  end
end
