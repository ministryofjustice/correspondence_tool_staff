module PageObjects
  module Pages
    module Assignments
      class NewPage < SitePrism::Page
        set_url '/cases/{id}/assignments/new'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :assign_to, :xpath, '//fieldset[contains(.,"Assign to")]' do
          elements :teams, 'label'
        end

        element :create_and_assign_case, '.button'
      end
    end
  end
end
