module PageObjects
  module Pages
    module Admin
      module Cases
        class NewICOPage < PageObjects::Pages::Base
          set_url '/admin/cases/new/ico'

          sections :notices, '.notice-summary' do
            element :heading, '.notice-summary-heading'
          end

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'


          element :ico_reference_number, '#case_ico_ico_reference_number'
          element :ico_officer_name, '#case_ico_ico_officer_name'

          element :original_case_number, '#case_ico_original_case_number'
          element :original_case_number_error, '.js-original-case .error-message'
          section :original_case,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  '.js-original-case-and-friends .grid-row:first-child'
          element :link_original_case, :xpath, '//button[contains(.,"Link original case")]'


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

          element :target_state, '#case_ico_target_state'

          element :submit_button, '.button'

          def set_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end
        end
      end
    end
  end
end
