module PageObjects
  module Pages
    module Cases
      class DataRequestProbationEmailPage < SitePrism::Page
        set_url "/cases/{case_id}/data_requests/{id}/probation_send_email"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        element :page_banner, ".moj-banner__message"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :commissioning_document, ".commissioning-document" do
          section :data, ".grid-row.data-request" do
            element :email, ".data-request__email"
          end
        end

        element :button_continue, ".button"
        element :link_cancel, ".data_request_cancel"
      end
    end
  end
end
