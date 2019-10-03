module PageObjects
  module Pages
    module Cases
      class SearchPage < PageObjects::Pages::Base  #SitePrism::Page
        include PageObjects::FilterMethods

        set_url '/cases/search'

        sections :notices, '.notice-summary' do
          element :heading, '.notice-summary-heading'
        end

        element :search_query, 'input[type="search"]'
        element :search_button, 'input.button#search-button'

        section :case_filters, '#case-filters' do
          element :filter_cases_link, '#filter-cases-link'
          element :filter_type_link, '#filter-type-link'
          element :filter_timeliness_link, '#filter-timeliness-link'
          element :filter_status_link, '#filter-status-link'
          element :filter_deadline_link, '#filter-deadline-link'
          element :filter_exemption_link, '#filter-exemptions-link'
          element :apply_filters_button, '#apply-filters-button'
        end

        element :filter_cases_accordion, '#filter-cases-accordion'
        elements :filter_crumbs, '.filter-crumb a'

        element :search_results_count, '.search-results-summary'
        element :download_cases_link, '.download-cases-link'

        sections :case_list, '.report tbody tr' do
          element :number, 'td[aria-label="Case number"]'
          element :request_detail, 'td[aria-label="Request detail"]'
          element :draft_deadline, 'td[aria-label="Draft deadline"]'
          element :external_deadline, 'td[aria-label="Final deadline"]'
          element :status, 'td[aria-label="Status"]'
          element :who_its_with, 'td[aria-label="With"]'
        end

        section :filter_type_content,
                PageObjects::Sections::Cases::TypeFilterPanelSection,
                '#filter-type-content'
        section :filter_timeliness_content,
                PageObjects::Sections::Cases::TimelinessFilterPanelSection,
                '#filter-timeliness-content'
        section :filter_status_content,
                PageObjects::Sections::Cases::OpenCaseStatusFilterPanelSection,
                '#filter-status-content'
        section :filter_deadline_content,
                PageObjects::Sections::Cases::DeadlineFilterPanelSection,
                '#filter-deadline-content'
        section :filter_exemption_content,
                PageObjects::Sections::Cases::ExemptionFilterPanelSection,
                '#filter-exemptions-content'

        element :found_no_results_copy, '.search-no-results'
      end
    end
  end
end



