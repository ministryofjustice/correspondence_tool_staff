module PageObjects
  module Pages
    module Cases
      class DataRequestAreaEmailConfirmationPage < SitePrism::Page
        set_url "/cases/{case_id}/data_request_areas/{id}/send_email"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        element :page_banner, ".moj-banner__message"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :button_send_email, ".data_request_area_send_email"
        element :link_cancel, ".data_request_cancel"
      end
    end
  end
end
