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

        section :case_filters, '.case-filters > details' do
          element :filter_cases_link, '.case-filters__summary--outer'
          element :filter_status_link, '.case-filters__container details:nth-child(1) summary'
          element :filter_type_link, '.case-filters__container details:nth-child(2) summary'
          element :filter_timeliness_link, '.case-filters__container details:nth-child(3) summary'
          element :filter_deadline_link, '.case-filters__container details:nth-child(4) summary'
          element :filter_exemption_link, '.case-filters__container details:nth-child(5) summary'
          element :apply_filters_button, '.case-filters__container > input'
        end

        element :filter_cases_accordion, '.case-filters__container'
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
        section :filter_exemption_content,
                PageObjects::Sections::Cases::ExemptionFilterPanelSection,
                '.case-filters__content--exemptions'

        element :found_no_results_copy, '.search-no-results'
      end
    end
  end
end



