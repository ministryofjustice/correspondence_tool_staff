module PageObjects
  module Sections
    module Cases
      module OverturnedFOI
        class FormSection < SitePrism::Section
          include SitePrism::Support::DropInDropzone

          element :date_received_day, '#case_overturned_foi_received_date_dd'
          element :date_received_month, '#case_overturned_foi_received_date_mm'
          element :date_received_year, '#case_overturned_foi_received_date_yyyy'

          element :final_deadline_day, '#case_overturned_foi_external_deadline_dd'
          element :final_deadline_month, '#case_overturned_foi_external_deadline_mm'
          element :final_deadline_year, '#case_overturned_foi_external_deadline_yyyy'

          section :reply_method, :xpath, '//fieldset[contains(.,"Reply method")]' do
            element :send_by_email,
                    '#case_overturned_foi_reply_method_send_by_email',
                    visible: false
            element :email, '#case_overturned_foi_email'
            element :send_by_post,
                    '#case_overturned_foi_reply_method_send_by_post',
                    visible: false
            element :postal_address, '#case_overturned_foi_postal_address'
          end
        end
      end
    end
  end
end
