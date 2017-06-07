module PageObjects
  module Pages
    module Assignments
      class EditPage < SitePrism::Page
        set_url '/cases/{case_id}/assignments/{id}/edit'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        element :message_label, '.request--heading'
        element :message, '.request--message'

        element :accept_radio, 'label[for="assignment_state_accepted"]'
        element :confirm_button, '.button'


      end
    end
  end
end
