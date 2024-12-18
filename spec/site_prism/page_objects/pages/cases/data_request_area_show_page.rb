module PageObjects
  module Pages
    module Cases
      class DataRequestAreaShowPage < SitePrism::Page
        set_url "/cases/{case_id}/data_request_areas/{data_request_area_id}"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        element :page_banner, ".moj-banner__message"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :location, ".data_request_area_location"

        section :data_requests,
                PageObjects::Sections::Cases::DataRequestsSection, ".data-requests"

        section :commissioning_document, ".commissioning-document" do
          section :row, "tbody.document tr" do
            element :request_document, "td:nth-child(1)"
            element :last_updated, "td:nth-child(2)"
            element :actions, "td:nth-child(3)"
          end
          element :button_send_email, ".data_request_area_send_email"

          section :email_row, "tbody.email_details tr" do
            element :email_type, "td:nth-child(1)"
            element :email_address, "td:nth-child(2)"
            element :created_at, "td:nth-child(3)"
            element :status, "td:nth-child(4)"
          end
        end
      end
    end
  end
end
