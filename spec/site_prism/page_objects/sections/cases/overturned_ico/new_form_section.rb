module PageObjects
  module Sections
    module Cases
      module OverturnedICO
        class NewFormSection < SitePrism::Section
          include SitePrism::Support::DropInDropzone

          element :correspondence_type,
                  '#correspondence_type',
                  visible: false
          element :original_ico_appeal_id,
                  :xpath,
                  ".//input[contains(@name,'original_ico_appeal_id')]",
                  visible: false
          element :ico_appeal_info, '.heading-medium'

          section :final_deadline,
                  PageObjects::Sections::Shared::GovUKDateSection,
                  :xpath,
                  '//fieldset[contains(.,"Final deadline")]'
        end
      end
    end
  end
end
