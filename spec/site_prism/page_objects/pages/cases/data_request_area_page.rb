module PageObjects
  module Pages
    module Cases
      class DataRequestAreaPage < PageObjects::Pages::Base
        set_url "/cases/{case_id}/data_request_areas{/new}"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :form, "#new_data_request_area" do
          element :location, 'input[name*="[location]"]'
          element :data_request_area_type, :xpath,
                  '//fieldset[contains(.,"What data is needed?")]'

          def choose_area_request_type(request_type)
            make_radio_button_choice("data_request_area_data_request_area_type_#{request_type}")
          end

          def make_radio_button_choice(choice_id)
            selector = "input##{choice_id}"

            if Capybara.current_driver == Capybara.javascript_driver
              find(selector, visible: false).click
            else
              find(selector).set(true)
            end
          end

          element :submit_button, ".button"
        end
      end
    end
  end
end
