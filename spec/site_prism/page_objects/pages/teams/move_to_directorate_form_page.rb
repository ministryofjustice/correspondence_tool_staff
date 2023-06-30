module PageObjects
  module Pages
    module Teams
      class MoveToDirectorateFormPage < SitePrism::Page
        set_url "/teams/{id}/move_to_directorate_form"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :heading, ".page-heading--primary"
        element :subhead, ".page-heading--secondary"

        element :move_button, ".update-directorate-button"
      end
    end
  end
end
