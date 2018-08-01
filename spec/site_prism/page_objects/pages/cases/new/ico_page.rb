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

          element :ico_reference_number, '#case_ico_ico_reference_number'
          element :ico_officer_name, '#case_ico_ico_officer_name'

          element :original_case_number, '#case_ico_original_case_number'
          element :original_case_number_error, '.js-original-case .error-message'
          section :original_case,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  '.js-original-case-and-friends .grid-row:first-child'
          element :link_original_case, :xpath, '//button[contains(.,"Link original case")]'

          element :related_case_number, '#case_ico_related_case_number'
          element :related_case_number_error, '.js-related-case .error-message'
          section :related_cases,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  '.js-related-case-report'
          element :link_related_case, :xpath, '//button[contains(.,"Link related case")]'



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

          def set_original_case_number(original_case_number)
            self.original_case_number.set original_case_number
            link_original_case.click
            has_original_case?
          end

          def add_related_case(case_number)
            before_count = related_cases.linked_records.count
            self.related_case_number.set case_number
            link_related_case.click
            has_related_cases?
            related_cases.has_linked_records(count: before_count + 1)
          end

          def fill_in_case_details(params={})
            # We can't rely on the factory to link original case since we only
            # build the kase below (factory relies on after-create hook) and
            # the point of this function is to exercise the front-end so we
            # should be linking by adding the linked cases through it.
            original_case = params.delete(:original_case)
            related_cases = params.delete(:related_cases)
            kase = FactoryBot.build :ico_foi_case, params

            set_received_date(kase.received_date)
            set_final_deadline_date(kase.external_deadline)

            ico_officer_name.set kase.ico_officer_name
            ico_reference_number.set kase.ico_reference_number
            set_original_case_number(original_case.number)
            related_cases.each { |c| add_related_case(c.number) }

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
