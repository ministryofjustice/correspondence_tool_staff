module PageObjects
  module Pages
    module Cases
      module New
        class ICOPage < PageObjects::Pages::Base
          set_url '/cases/new/ico'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'
          element :original_case_type, :xpath,
                  '//fieldset[contains(.,"Type")]'

          element :ico_reference_number, '#case_ico_ico_reference_number'

          element :date_received_day, '#case_ico_received_date_dd'
          element :date_received_month, '#case_ico_received_date_mm'
          element :date_received_year, '#case_ico_received_date_yyyy'

          element :external_deadline_day, '#case_ico_external_deadline_dd'
          element :external_deadline_month, '#case_ico_external_deadline_mm'
          element :external_deadline_year, '#case_ico_external_deadline_yyyy'

          element :subject, '#case_ico_subject'
          element :case_details, '#case_ico_message'

          element :dropzone_container, '.dropzone'

          # only shows up when using drop_in_dropzone
          element :uploaded_request_file_input, '#uploadedRequestFileInput'

          element :submit_button, '.button'

          def set_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end

          def set_final_deadline_date(final_deadline_date)
            external_deadline_day.set(final_deadline_date.day)
            external_deadline_month.set(final_deadline_date.month)
            external_deadline_year.set(final_deadline_date.year)
          end

          def choose_original_case_type(original_case_type)
            css_class = "case_ico_original_case_type_#{original_case_type}"
            make_radio_button_choice(css_class)
          end

          def fill_in_case_details(params={})
            original_case_type = params.delete(:original_case_type)
            kase = FactoryBot.build :ico_foi_case, params

            choose_original_case_type(original_case_type.downcase)

            set_received_date(kase.received_date)
            set_final_deadline_date(kase.external_deadline)

            ico_reference_number.set kase.ico_reference_number
            subject.set kase.subject
            case_details.set kase.message
            kase.uploaded_request_files.each do |file|
              drop_in_dropzone(file)
            end

            kase
          end

          def drop_in_dropzone(file_path)
            super file_path: file_path,
                  input_name: dropzone_container['data-file-input-name'],
                  container_selector: '#uploaded-request-files-fields'
          end
        end
      end
    end
  end
end
