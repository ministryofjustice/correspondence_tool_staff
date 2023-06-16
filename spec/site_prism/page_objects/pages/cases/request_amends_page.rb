module PageObjects
  module Pages
    module Cases
      class RequestAmendsPage < SitePrism::Page
        set_url "/cases/{id}/amendments/new"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :clearance,
                PageObjects::Sections::Cases::ClearanceCopySection, ".clearance-copy"

        element :draft_compliant, :xpath, '//fieldset[contains(.,"draft compliant")]'

        element :submit_button, ".button"
      end
    end
  end
end
