module PageObjects
  module Pages
    module Cases
      class SearchPage < PageObjects::Pages::Base  #SitePrism::Page
        set_url '/cases/search'

        sections :notices, '.notice-summary' do
          element :heading, '.notice-summary-heading'
        end

        section :filter_tab_links, '.ct-tab-container' do
          element :type_tab, 'a[href="#ct-tab-panel-type"]'
          element :status_tab, 'a[href="#ct-tab-panel-status"]'
          element :assigned_to_tab, 'a[href="#ct-tab-panel-assigned-to"]'
          element :exemption_tab, 'a[href="#ct-tab-panel-exemption"]'
        end

        element :search_query, 'input[type="search"]'
        element :search_button, 'input.button#search-button'

        element :search_results_count, '.search-results-summary'

        sections :case_list, '.report tbody tr' do
          element :number, 'td[aria-label="Case number"]'
          element :request_detail, 'td[aria-label="Request detail"]'
          element :draft_deadline, 'td[aria-label="Draft deadline"]'
          element :external_deadline, 'td[aria-label="Final deadline"]'
          element :status, 'td[aria-label="Status"]'
          element :who_its_with, 'td[aria-label="With"]'
        end

        section :filters, '.ct-tab-container' do
          elements :options, '.ct-tab-item'
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
        end


        element :found_no_results_copy, '.search-no-results'

        def filter_on_exemptions(common: nil, all: nil)
          filter_tab_links.exemption_tab.click
          if common.present?
            common.each do |checkbox_code|
              checkbox_name = "#{checkbox_code}_checkbox"
              # checkbox_id = filters.exemption_filter_panel.most_used.__send__(checkbox_name)['for']
              filters.exemption_filter_panel.most_used.__send__(checkbox_name).click
            end
          end
          if all.present?
            all.each do |checkbox_code|
              checkbox_name = "#{checkbox_code}_checkbox"
              filters.exemption_filter_panel.exemption_all.__send__(checkbox_name).click
            end
          end
          filters.exemption_filter_panel.apply_filter_button.click
        end
      end
    end
  end
end



