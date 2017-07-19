require 'page_objects/pages/cases_page'

module PageObjects
  module Pages
    module Cases
      class OpenCasesPage < PageObjects::Pages::CasesPage
        # This page is just a version of CasesPage, so look at that for the
        # page structure.
        set_url '/cases/open{?timeliness*}'
      end
    end
  end
end
