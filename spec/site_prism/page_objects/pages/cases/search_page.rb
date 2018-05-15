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

        section :filter_tab_links, '.ct-tab-container' do
          element :type_tab, 'a[href="#ct-tab-panel-type"]'
          element :status_tab, 'a[href="#ct-tab-panel-status"]'
          element :assigned_to_tab, 'a[href="#ct-tab-panel-assigned-to"]'
          element :exemption_tab, 'a[href="#ct-tab-panel-exemption"]'
          element :deadline_tab, 'a[href="#ct-tab-panel-final-deadline"]'
        end

        elements :filter_crumbs, '.filter-crumbs a'

        element :search_results_count, '.search-results-summary'

        sections :case_list, '.report tbody tr' do
          element :number, 'td[aria-label="Case number"]'
          element :request_detail, 'td[aria-label="Request detail"]'
          element :draft_deadline, 'td[aria-label="Draft deadline"]'
          element :external_deadline, 'td[aria-label="Final deadline"]'
          element :status, 'td[aria-label="Status"]'
          element :who_its_with, 'td[aria-label="With"]'
        end

        element :filters, '.ct-tab-container'

        section :status_filter_panel,
                PageObjects::Sections::Cases::StatusFilterPanelSection,
                '#ct-tab-panel-status'
        section :type_filter_panel,
                PageObjects::Sections::Cases::TypeFilterPanelSection,
                '#ct-tab-panel-type'
        section :assigned_to_filter_panel,
                PageObjects::Sections::Cases::AssignedToFilterPanelSection,
                '#ct-tab-panel-assigned-to'
        section :exemption_filter_panel,
                PageObjects::Sections::Cases::ExemptionFilterPanelSection,
                '#ct-tab-panel-exemption'
        section :deadline_filter_panel,
                PageObjects::Sections::Cases::DeadlineFilterPanelSection,
                '#ct-tab-panel-final-deadline'


        element :found_no_results_copy, '.search-no-results'
      end
    end
  end
end



