module PageObjects
  module Sections
    module Cases
      module OverturnedICO
        class NewFormSection < SitePrism::Section
          include SitePrism::Support::DropInDropzone

          element :correspondence_type,
                  "#correspondence_type",
                  visible: false
          element :original_ico_appeal_id,
                  :xpath,
                  ".//input[contains(@name,'original_ico_appeal_id')]",
                  visible: false
          element :ico_appeal_info, ".heading-medium"

          section :final_deadline,
                  PageObjects::Sections::Shared::GovUKDateSection,
                  :xpath,
                  '//fieldset[contains(.,"Final deadline")]'

          section :flag_for_disclosure_specialists, :xpath,
                  '//fieldset[contains(.,"Flag for disclosure specialists")]' do
            element :yes, 'input[value="yes"]'
            element :no, 'input[value="no"]'
          end

          def choose_flag_for_disclosure_specialists(choice = "yes", case_type: "foi")
            selector = "overturned_#{case_type.gsub('::', '_')}_flag_for_disclosure_specialists_#{choice}"
            make_radio_button_choice(selector)
          end

          def make_radio_button_choice(choice_id)
            selector = "input##{choice_id}"

            if Capybara.current_driver == Capybara.javascript_driver
              find(selector, visible: false).click
            else
              find(selector).set(true)
            end
          end
        end
      end
    end
  end
end
