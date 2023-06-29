require "page_objects/pages/cases_page"

module PageObjects
  module Pages
    module Cases
      class OpenCasesPage < PageObjects::Pages::CasesPage
        include PageObjects::FilterMethods

        # This page is just a version of CasesPage, so look at that for the
        # page structure.
        set_url "/cases/open"
        set_url_matcher(/cases\/(open|my_open)(\/(in_time))?/)

        element :search_query, 'input[type="search"]'
        element :search_button, "input.button#search-button"

        section :case_filters, ".case-filters > details" do
          element :filter_cases_link, ".case-filters__summary--outer"
          element :filter_status_link, "#filter_status_content_btn"
          element :filter_open_status_link, "#filter_open_case_status_content_btn"
          element :filter_type_link, "#filter_case_type_content_btn"
          element :filter_complaint_type_link, "#filter_complaint_type_content_btn"
          element :filter_sensitivity_link, "#filter_sensitivity_content_btn"
          element :filter_timeliness_link, "#filter_timeliness_content_btn"
          element :filter_external_deadline_link, "#filter_external_deadline_content_btn"
          element :filter_exemption_link, "#filter_exemption_content_btn"
          element :apply_filters_button, ".case-filters__container > input"
        end

        element :filter_cases_accordion, ".case-filters__container"

        section :filter_open_status_content,
                PageObjects::Sections::Cases::OpenCaseStatusFilterPanelSection,
                "#filter_open_case_status_content"
        section :filter_type_content,
                PageObjects::Sections::Cases::TypeFilterPanelSection,
                "#filter_case_type_content"
        section :filter_complaint_type_content,
                PageObjects::Sections::Cases::TypeComplaintFilterPanelSection,
                "#filter_complaint_type_content"
        section :filter_sensitivity_content,
                PageObjects::Sections::Cases::TriggerFlagFilterPanelSection,
                "#filter_sensitivity_content"
        section :filter_timeliness_content,
                PageObjects::Sections::Cases::TimelinessFilterPanelSection,
                "#filter_timeliness_content"
        section :filter_external_deadline_content,
                PageObjects::Sections::Cases::DeadlineFilterPanelSection,
                "#filter_external_deadline_content"

        elements :filter_crumbs, ".filter-crumb a"

        element :search_results_count, ".search-results-summary"
      end
    end
  end
end
