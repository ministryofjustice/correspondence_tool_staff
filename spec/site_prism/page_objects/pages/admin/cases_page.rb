module PageObjects
  module Pages
    module Admin
      class CasesPage < SitePrism::Page
        set_url "/admin/cases"

        sections :notices, ".notice-summary" do
          element :heading, ".notice-summary-heading"
        end

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        sections :tabs, ".section-tabs .tab" do
          element :tab_link, "a"
          element :count, ".in-time-count"
        end
        section :active_tab, ".section-tabs .tab.active" do
          element :link, "a"
        end

        element :create_case_button, 'a.button[href="/admin/cases/new/"]'

        sections :case_list, ".case_row" do
          element :id, "td:nth-child(1)"
          element :number, "td:nth-child(2)"
          element :request_detail, "td:nth-child(3)"
          element :status, "td:nth-child(4)"
          element :who_its_with, 'td[aria-label="With"]'
        end

        section :service_feedback, PageObjects::Sections::ServiceFeedbackSection, "#feedback"
        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :pagination, PageObjects::Sections::PaginationSection, ".pagination"

        def case_numbers
          case_list.map do |row|
            row.number.text.delete("Link to case").delete("\n")
          end
        end
      end
    end
  end
end
