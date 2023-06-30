module PageObjects
  module Sections
    module Cases
      class BypassPressOfficeOptionSection < SitePrism::Section
        element :radio_yes, 'label[for="bypass_approval_press_office_approval_required_true"]'
        element :radio_no, 'label[for="bypass_approval_press_office_approval_required_false"]'

        element :bypass_reason_text, "#bypass_approval_bypass_message"
        element :clear_response_button, "input.button"
      end
    end
  end
end
