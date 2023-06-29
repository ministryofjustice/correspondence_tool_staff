module PageObjects
  module Pages
    module Users
      class ShowPage < SitePrism::Page
        set_url "/users/{user_id}"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                ".page-heading"

        element :download_cases_link, ".download-cases-link"

        sections :case_list, ".case_row" do
          element :number, 'td[aria-label="Case number"]'
          element :type, 'td[aria-label="Type"]'
          element :request_detail, 'td[aria-label="Request detail"]'
          element :draft_deadline, 'td[aria-label="Draft deadline"]'
          element :external_deadline, 'td[aria-label="Final deadline"]'
          element :status, 'td[aria-label="Status"]'
        end
      end
    end
  end
end
