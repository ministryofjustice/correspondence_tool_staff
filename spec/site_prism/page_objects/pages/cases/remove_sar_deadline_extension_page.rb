module PageObjects
  module Pages
    module Cases
      class RemoveSARDeadlineExtensionPage < SitePrism::Page
        set_url "/cases/{id}/sar_extensions/edit"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection,
                ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                ".page-heading"

        element :copy, ".action-copy"

        element :reason_for_removing_extension, "#case_reason_for_removing_extension"

        element :submit_button, ".button"

        def set_reason_for_removing_extension(message)
          reason_for_removing_extension.set(message)
        end
      end
    end
  end
end
