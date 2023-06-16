module PageObjects
  module Pages
    module Cases
      class RemoveClearanceFormPage < PageObjects::Pages::Base
        set_url "/cases/{id}/clearances/remove_clearance"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        # section :removal_detail do
        #   element :removal_info, 'div'
        # end

        element :label, ".label.form-label"
        element :textarea, "form-control#unflag_for_clearance_message"
        element :submit_button, ".button"
      end
    end
  end
end
