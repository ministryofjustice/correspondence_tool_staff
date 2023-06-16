module PageObjects
  module Pages
    module Cases
      # SitePrism::Page
      class SearchPage < PageObjects::Pages::Base
        include PageObjects::FilterMethods

        set_url "/cases/search"

        sections :notices, ".notice-summary" do
          element :heading, ".notice-summary-heading"
        end

        element :search_query, 'input[type="search"]'
        element :search_button, "input.button#search-button"

        section :case_filters, ".case-filters > details" do
          element :filter_cases_link, ".case-filters__summary--outer"
          element :filter_status_link, "#filter_status_content_btn"
          element :filter_open_status_link, "#filter_open_case_status_content_btn"
          element :filter_type_link, "#filter_case_type_content_btn"
          element :filter_sensitivity_link, "#filter_sensitivity_content_btn"
          element :filter_timeliness_link, "#filter_timeliness_content_btn"
          element :filter_external_deadline_link, "#filter_external_deadline_content_btn"
          element :filter_exemption_link, "#filter_exemption_content_btn"
          element :apply_filters_button, ".case-filters__container > input"
        end

        element :filter_cases_accordion, ".case-filters__container"
        elements :filter_crumbs, ".filter-crumb a"

        element :search_results_count, ".search-results-summary"
        element :download_cases_link, ".download-cases-link"

        sections :case_list, ".report tbody tr" do
          element :number, 'td[aria-label="Case number"]'
          element :request_detail, 'td[aria-label="Request detail"]'
          element :draft_deadline, 'td[aria-label="Draft deadline"]'
          element :external_deadline, 'td[aria-label="Final deadline"]'
          element :status, 'td[aria-label="Status"]'
          element :who_its_with, 'td[aria-label="With"]'
        end

        section :filter_status_content,
                PageObjects::Sections::Cases::OpenCaseStatusFilterPanelSection,
                "#filter_status_content"
        section :filter_open_status_content,
                PageObjects::Sections::Cases::OpenCaseStatusFilterPanelSection,
                "#filter_open_case_status_content"
        section :filter_type_content,
                PageObjects::Sections::Cases::TypeFilterPanelSection,
                "#filter_case_type_content"
        section :filter_sensitivity_content,
                PageObjects::Sections::Cases::TriggerFlagFilterPanelSection,
                "#filter_sensitivity_content"
        section :filter_timeliness_content,
                PageObjects::Sections::Cases::TimelinessFilterPanelSection,
                "#filter_timeliness_content"
        section :filter_external_deadline_content,
                PageObjects::Sections::Cases::DeadlineFilterPanelSection,
                "#filter_external_deadline_content"
        section :filter_exemption_content,
                PageObjects::Sections::Cases::ExemptionFilterPanelSection,
                "#filter_exemption_content"

        element :found_no_results_copy, ".search-no-results"
      end
    end
  end
end
