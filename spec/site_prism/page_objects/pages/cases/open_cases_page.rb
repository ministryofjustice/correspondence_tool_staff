require 'page_objects/pages/cases_page'

module PageObjects
  module Pages
    module Cases
      class OpenCasesPage < PageObjects::Pages::CasesPage
        include PageObjects::FilterMethods

        # This page is just a version of CasesPage, so look at that for the
        # page structure.
        set_url '/cases/open'

        section :filter_tab_links, '.ct-tab-container' do
          element :type_tab, 'a[href="#ct-tab-panel-type"]'
          element :timeliness_tab, 'a[href="#ct-tab-panel-timeliness"]'
          element :status_tab, 'a[href="#ct-tab-panel-status"]'
          element :deadline_tab, 'a[href="#ct-tab-panel-final-deadline"]'
          element :assigned_to_tab, 'a[href="#ct-tab-panel-assigned-to"]'
        end

        # section :filters, '.ct-tab-container' do
        elements :options, '.ct-tab-item'

        section :type_filter_panel,
                PageObjects::Sections::Cases::TypeFilterPanelSection,
                '#ct-tab-panel-type'
        section :timeliness_filter_panel,
                PageObjects::Sections::Cases::TimelinessFilterPanelSection,
                '#ct-tab-panel-timeliness'
        section :status_filter_panel,
                PageObjects::Sections::Cases::OpenCaseStatusFilterPanelSection,
                '#ct-tab-panel-status'
        section :deadline_filter_panel,
                PageObjects::Sections::Cases::DeadlineFilterPanelSection,
                '#ct-tab-panel-final-deadline'
        section :assigned_to_filter_panel,
                PageObjects::Sections::Cases::AssignedToFilterPanelSection,
                '#ct-tab-panel-assigned-to'

        elements :filter_crumbs, '.filter-crumb a'
      end
    end
  end
end
