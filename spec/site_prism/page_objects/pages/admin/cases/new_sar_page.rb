module PageObjects
  module Pages
    module Admin
      module Cases
        class NewSARPage < PageObjects::Pages::Base
          set_url '/admin/cases/new/sar'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#case_sar_subject_full_name'
          element :subject_type, :xpath,
                  '//fieldset[contains(.,"Type of data subject")]'
          element :third_party, :xpath,
                  "//fieldset[contains(.,\"being requested on someone's behalf\")]"
          element :requester_full_name, '#case_sar_name'

          element :received_date, '#case_sar_received_date'
          element :created_at, '#case_sar_created_at'

          element :subject, '#case_sar_subject'
          element :full_request, '#case_sar_message'
          element :dropzone_container, '.dropzone'

          # only shows up when using drop_in_dropzone
          element :uploaded_request_file_input, '#uploadedRequestFileInput'

          element :reply_method, :xpath,
                  '//fieldset[contains(.,"Where the information should be sent")]'
          element :email, '#case_sar_email'
          element :postal_address, '#case_sar_postal_address'

          element :submit_button, '.button'

          def set_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end

          def fill_in_case_details(params={})
            kase = FactoryGirl.build :sar_case, params

            subject_full_name.set kase.subject_full_name
            choose_subject_type kase.subject_type
            if kase.third_party?
              choose_third_party true
              requester_full_name.set kase.name
            else
              choose_third_party false
            end
            set_received_date kase.received_date
            subject.set kase.subject
            full_request.set kase.message
            kase.uploaded_request_files.try(:each) do |file|
              drop_in_dropzone(file)
            end
            if kase.send_by_email?
              choose_reply_method 'send_by_email'
              email.set kase.email
            elsif kase.send_by_post?
              choose_reply_method 'send_by_post'
              postal_address.set kase.postal_address
            end

            kase
          end

          def drop_in_dropzone(file_path)
            super file_path: file_path,
                  input_name: dropzone_container['data-file-input-name'],
                  container_selector: '#delivery-method-fields'
          end
        end
      end
    end
  end
end
