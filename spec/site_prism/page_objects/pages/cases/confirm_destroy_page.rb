module PageObjects
  module Pages
    module Cases
      class ConfirmDestroyPage < SitePrism::Page
        set_url '/cases/{id}/confirm_destroy'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :delete_copy, '.delete-copy p'

        element :warning, '.delete-copy .notice'

        element :confirm_button, '.button'
        element :cancel, 'a.acts-like-button.button-left-spacing'
      end
    end
  end
end
