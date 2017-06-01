require 'page_objects/pages/cases_page'

module PageObjects
  module Pages
    module Cases
      class OpenCasesPage < PageObjects::Pages::CasesPage
        set_url '/cases/open{?timeliness*}'
      end
    end
  end
end
