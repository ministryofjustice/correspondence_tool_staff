module PageObjects
  module Pages
    module Cases
      class NewCaseLinkPage < PageObjects::Pages::Base
        set_url '/cases/{id}/new_case_link'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :linked_case_number_label, 'label.form-label'
        element :linked_case_number_field, 'input[type="text"].form-control'

        element :submit_button, '.button'

        def create_a_new_case_link
          kase = FactoryGirl.build :case, params
          linked_case_number_field.set kase.number
          submit_button.click
          kase # return new case should you need to use it for further tests
        end

      end
    end
  end
end
