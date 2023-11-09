module PageObjects
  module Pages
    module Cases
      class DataRequestShowPage < SitePrism::Page
        set_url "/cases/{case_id}/data_requests/{id}"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :data, ".grid-row.data-request" do
          element :number, ".data-request__number"
          element :location, ".data_request_location"
          element :request_type, ".data_request_request_type"
          element :date_requested, ".data_request_date_requested"
          element :date_from, ".data_request_date_from"
          element :date_to, ".data_request_date_to"
          element :pages_received, ".data_request_pages_received"
          element :completed, ".data_request_completed"
          element :date_completed, ".data_request_date_completed"
        end

        element :link_edit, ".data-requests__action"

        section :commissioning_document, ".commissioning-document" do
          section :row, "tbody.document tr" do
            element :request_document, "td:nth-child(1)"
            element :last_updated, "td:nth-child(2)"
            element :actions, "td:nth-child(3)"
          end
          element :button_send_email, ".button-high"

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
