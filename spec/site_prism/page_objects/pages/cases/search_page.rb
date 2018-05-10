module PageObjects
  module Pages
    module Cases
      class SearchPage < PageObjects::Pages::Base  #SitePrism::Page
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
        end

        elements :filter_crumbs, '.filter-crumbs input[type="submit"]'

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

        def filter_on(filter_name, *checkboxes)
          tab_link_name = "#{filter_name}_tab"
          filter_tab_links.__send__(tab_link_name).click

          checkboxes.each do |checkbox_name|
            checkbox_id = "search_query_filter_#{checkbox_name}"
            make_check_box_choice(checkbox_id)
          end

          filter_panel_name = "#{filter_name}_filter_panel"
          filters.__send__(filter_panel_name).apply_filter_button.click
        end

        def remove_filter_on(filter_name, *checkboxes)
          tab_link_name = "#{filter_name}_tab"
          filter_tab_links.__send__(tab_link_name).click

          checkboxes.each do |checkbox_name|
            checkbox_id = "search_query_filter_#{checkbox_name}"
            remove_check_box_choice(checkbox_id)
          end

          filter_panel_name = "#{filter_name}_filter_panel"
          filters.__send__(filter_panel_name).apply_filter_button.click
        end

        def filter_on_exemptions(common: nil, all: nil)
          open_filter(:exemption)
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

        def filter_crumb_for(crumb_text)
          filter_crumbs.find { |crumb| crumb.value == crumb_text }
        end
      end
    end
  end
end



