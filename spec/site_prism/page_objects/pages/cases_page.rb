module PageObjects
  module Pages
    class CasesPage < PageObjects::Pages::Base
      set_url "/"

      sections :notices, ".notice-summary" do
        element :heading, ".notice-summary-heading"
      end

      section :primary_navigation,
              PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

      section :homepage_navigation,
              PageObjects::Sections::HomepageNavigationSection, "#homepage-navigation"

      section :state_filter, ".state-filter" do
        elements :check_boxes, "label"
        element :apply_filter_button, 'input[value="Filter"]'
      end

      sections :tabs, ".section-tabs .tab" do
        element :tab_link, "a"
        element :count, ".in-time-count"
      end
      section :active_tab, ".section-tabs .tab.active" do
        element :link, "a"
      end

      section :user_card, PageObjects::Sections::UserCardSection, ".user-card"
      sections :case_list, ".case_row" do
        element :number, 'td[aria-label="Case number"]'
        element :flag, 'td[aria-label="Flag"]'
        element :type, 'td[aria-label="Type"]'
        element :request_detail, 'td[aria-label="Request detail"]'
        element :draft_deadline, 'td[aria-label="Draft deadline"]'
        element :external_deadline, 'td[aria-label="Final deadline"]'
        element :status, 'td[aria-label="Status"]'
        element :who_its_with, 'td[aria-label="With"]'
        element :message_notification, 'td[aria-label="Conversations"] img'
      end

      element :remove_original_link, ".js-remove-original"
      element :new_case_button, 'a.button[href="/cases/new"]'
      section :service_feedback, PageObjects::Sections::ServiceFeedbackSection, "#feedback"
      section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

      section :pagination, PageObjects::Sections::PaginationSection, ".govuk-pagination"

      def case_numbers
        case_list.map do |row|
          row.number.text.delete("Case number").delete("\n")
        end
      end

      def choose_state(choice)
        make_check_box_choice("search_query_filter_open_case_status_#{choice}")
      end

      def row_for_case_number(number)
        Capybara.ignore_hidden_elements = false
        case_list.find do |row|
          row.number.text == "Case number #{number}"
        end
      ensure
        Capybara.ignore_hidden_elements = true
      end
    end
  end
end
