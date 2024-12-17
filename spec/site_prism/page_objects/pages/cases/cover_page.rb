module PageObjects
  module Pages
    module Cases
      class CoverPage < SitePrism::Page
        set_url "/cases/{id}/cover-page"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".cover-sheet__heading" do
          element :case_number, "li:first-child"
          element :subject_full_name, "li:nth-child(2)"
          element :prison_number, "li:nth-child(3)"
        end

        element :cover_sheet_address, ".cover-sheet__address"

        section :data_requests,
                PageObjects::Sections::Cases::DataRequestsSection, ".data-requests"

        element :final_deadline, ".heading--final-deadline"
      end
    end
  end
end
