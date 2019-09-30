require 'page_objects/pages/cases_page'

module PageObjects
  module Pages
    module Cases
      class OpenCasesPage < PageObjects::Pages::CasesPage
        include PageObjects::FilterMethods

        # This page is just a version of CasesPage, so look at that for the
        # page structure.
        set_url '/cases/open'
        set_url_matcher(/cases\/(open|my_open)(\/(in_time))?/)

        element :search_query, 'input[type="search"]'
        element :search_button, 'input.button#search-button'

        section :case_filters, '#case-filters' do
          element :filter_cases_link, '#filter-cases-link'
          element :filter_type_link, '#filter-type-link'
          element :filter_timeliness_link, '#filter-timeliness-link'
          element :filter_status_link, '#filter-status-link'
          element :filter_deadline_link, '#filter-deadline-link'
          element :apply_filters_button, '#apply-filters-button'
        end

        element :filter_cases_accordion, '#filter-cases-accordion'

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

        elements :filter_crumbs, '.filter-crumb a'

        element :search_results_count, '.search-results-summary'
      end
    end
  end
end
