module PageObjects
  module Pages
    module Cases
      class NewLetterPage < SitePrism::Page
        set_url '/cases/{case_id}/letters/{type}{/new}'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :new_letter_form, '#new_letter_form' do
          element :first_option, 'label', visible: true
        end

        element :submit_button, '.button'
      end
    end
  end
end

