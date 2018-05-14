require 'page_objects/pages/cases_page'

module PageObjects
  module Pages
    module Cases
      class OpenCasesPage < PageObjects::Pages::CasesPage
        # This page is just a version of CasesPage, so look at that for the
        # page structure.
        set_url '/cases/open/{timeliness}'

        section :filter_tab_links, '.ct-tab-container' do
          element :type_tab, 'a[href="#ct-tab-panel-type"]'
          element :status_tab, 'a[href="#ct-tab-panel-status"]'
          # element :assigned_to_tab, 'a[href="#ct-tab-panel-assigned-to"]'
          # element :exemption_tab, 'a[href="#ct-tab-panel-exemption"]'
        end

        section :filters, '.ct-tab-container' do
          elements :options, '.ct-tab-item'

          section :type_filter_panel,
                  PageObjects::Sections::Cases::TypeFilterPanelSection,
                  '#ct-tab-panel-type'
          section :status_filter_panel,
                  PageObjects::Sections::Cases::StatusFilterPanelSection,
                  '#ct-tab-panel-status'
          # section :assigned_to_filter_panel,
          #         PageObjects::Sections::Cases::AssignedToFilterPanelSection,
          #         '#ct-tab-panel-assigned-to'
          # section :exemption_filter_panel,
          #         PageObjects::Sections::Cases::ExemptionFilterPanelSection,
          #         '#ct-tab-panel-exemption'
        end
      end
    end
  end
end
