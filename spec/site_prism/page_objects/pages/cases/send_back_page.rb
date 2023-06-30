module PageObjects
  module Pages
    module Cases
      class SendBackPage < SitePrism::Page
        set_url "/cases/fois/{id}/send_back"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :optional_message, "#extra_comment"

        element :back_link, "a.acts-like-button"
        element :submit_button, ".button"

        def fill_in_optional_message(message)
          optional_message.set(message)
        end
      end
    end
  end
end
