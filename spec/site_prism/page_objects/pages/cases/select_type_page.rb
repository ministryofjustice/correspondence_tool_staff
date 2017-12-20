module PageObjects
  module Pages
    module Cases
      class SelectTypePage < PageObjects::Pages::Base
        set_url '/cases/new/select_type'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :case_type, :xpath,
                '//fieldset[contains(.,"Type")]'

        element :submit_button, '.button'


        def fill_in_case_type(choice)
          make_radio_button_choice("case_type_#{choice}")
          click_button 'Continue'
        end
      end
    end
  end
end
