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

          section :reply_method, :xpath, '//fieldset[contains(.,"Reply method")]' do
            element :send_by_email,
                    '#case_overturned_foi_reply_method_send_by_email,' \
                    '#case_overturned_sar_reply_method_send_by_email',
                    visible: false
            element :email,
                    '#case_overturned_foi_email,' \
                    '#case_overturned_sar_email'
            element :send_by_post,
                    '#case_overturned_foi_reply_method_send_by_post,' \
                    '#case_overturned_sar_reply_method_send_by_post',
                    visible: false
            element :postal_address,
                    '#case_overturned_foi_postal_address,' \
                    '#case_overturned_sar_postal_address'
          end
        end
      end
    end
  end
end
