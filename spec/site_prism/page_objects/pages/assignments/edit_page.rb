module PageObjects
  module Pages
    module Assignments
      class EditPage < SitePrism::Page
        set_url '/cases/{case_id}/assignments/{id}/edit'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

      end
    end
  end
end
