module PageObjects
  module Sections
    module Cases
      module OverturnedICO
        class NewFormSection < SitePrism::Section
          include SitePrism::Support::DropInDropzone

          element :ico_appeal_info, '.heading-medium'

          # Annoyingly, although this allows the presence of received_date to
          # be testable, it doesn't allow the fields within it to be set.
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
