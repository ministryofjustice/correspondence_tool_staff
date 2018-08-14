module PageObjects
  module Pages
    module Cases
      module New
        class SARPage < PageObjects::Pages::Base
          include SitePrism::Support::DropInDropzone

          set_url '/cases/new/sar'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#case_sar_subject_full_name'
          element :subject_type, :xpath,
                  '//fieldset[contains(.,"Who is the person the information is being requested about?")]'
          element :third_party, :xpath,
                  "//fieldset[contains(.,\"being requested on someone's behalf\")]"
          element :requester_full_name, '#case_sar_name'
          element :third_party_relationship, '#case_sar_third_party_relationship'

          element :date_received_day, '#case_sar_received_date_dd'
          element :date_received_month, '#case_sar_received_date_mm'
          element :date_received_year, '#case_sar_received_date_yyyy'

          element :subject, '#case_sar_subject'
          element :full_request, '#case_sar_message'
          element :dropzone_container, '.dropzone'

          # only shows up when using drop_in_dropzone
          element :uploaded_request_file_input, '#uploadedRequestFileInput'

          element :reply_method, :xpath,
                  '//fieldset[contains(.,"Where the information should be sent")]'
          element :email, '#case_sar_email'
          element :postal_address, '#case_sar_postal_address'

          element :flag_for_disclosure_specialists, :xpath,
                  '//fieldset[contains(.,"Flag for disclosure specialist")]'

          element :submit_button, '.button'

          def set_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end

          def fill_in_case_details(params={})
            kase = FactoryBot.build :sar_case, params

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
                  container_selector: '.dropzone'
          end

          def choose_flag_for_disclosure_specialists(choice = 'yes')
            make_radio_button_choice("case_sar_flag_for_disclosure_specialists_#{choice}")
          end
        end
      end
    end
  end
end
