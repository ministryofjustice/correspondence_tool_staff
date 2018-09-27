module PageObjects
  module Sections
    module Cases
      module OverturnedICO
        class NewFormSection < SitePrism::Section
          include SitePrism::Support::DropInDropzone

          element :ico_appeal_info, '.heading-medium'

          section :received_date,
                  PageObjects::Sections::Shared::GovUKDateSection,
                  'fieldset#received_date',
                  visible: false

          section :final_deadline,
                  PageObjects::Sections::Shared::GovUKDateSection,
                  :xpath,
                  '//fieldset[contains(.,"Final deadline")]'
        end
      end
    end
  end
end
