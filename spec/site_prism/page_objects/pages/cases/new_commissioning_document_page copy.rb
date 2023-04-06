module PageObjects
  module Pages
    module Cases
      class NewCommissioningDocumentPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{id}/commissioning_documents/new'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :form, '#new_commissioning_document' do
          elements :template_name, 'input[name*="[template_name]"]'

          def choose_template_name(template_name)
            make_radio_button_choice("commissioning_document_template_name_#{template_name}")
          end

          def make_radio_button_choice(choice_id)
            selector = "input##{choice_id}"

            if Capybara.current_driver == Capybara.javascript_driver
              find(selector, visible: false).click
            else
              find(selector).set(true)
            end
          end

          element :submit_button, '.button'
        end
      end
    end
  end
end
