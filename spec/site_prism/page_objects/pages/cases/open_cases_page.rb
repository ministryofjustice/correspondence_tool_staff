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

        section :case_filters, '.case-filters > details' do
          element :filter_cases_link, '.case-filters__summary--outer'
          element :filter_status_link, '.case-filters__container details:nth-child(1) summary'
          element :filter_type_link, '.case-filters__container details:nth-child(2) summary'
          element :filter_timeliness_link, '.case-filters__container details:nth-child(3) summary'
          element :filter_deadline_link, '.case-filters__container details:nth-child(4) summary'
          element :apply_filters_button, '.case-filters__container > input'
        end

        element :filter_cases_accordion, '.case-filters__container'

section :filter_status_content,
                PageObjects::Sections::Cases::OpenCaseStatusFilterPanelSection,
                '.case-filters__container details:nth-child(1) .case-filters__content'
        section :filter_type_content,
                PageObjects::Sections::Cases::TypeFilterPanelSection,
                '.case-filters__container details:nth-child(2) .case-filters__content'
        section :filter_timeliness_content,
                PageObjects::Sections::Cases::TimelinessFilterPanelSection,
                '.case-filters__container details:nth-child(3) .case-filters__content'
        section :filter_deadline_content,
                PageObjects::Sections::Cases::DeadlineFilterPanelSection,
                '.case-filters__container details:nth-child(4) .case-filters__content'

        elements :filter_crumbs, '.filter-crumb a'

        element :search_results_count, '.search-results-summary'
      end
    end
  end
end
