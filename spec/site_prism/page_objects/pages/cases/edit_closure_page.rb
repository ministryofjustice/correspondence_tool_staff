require 'page_objects/pages/cases/close_page'

module PageObjects
  module Pages
    module Cases
      class EditClosurePage < ClosePage
        set_url '/cases/{correspondence_type}/{id}/edit_closure'
      end
    end
  end
end

