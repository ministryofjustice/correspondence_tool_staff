module PageObjects
  module Sections
    module Cases
      module ICO
        class FormSection < SitePrism::Section
          include SitePrism::Support::DropInDropzone

          element :ico_reference_number, "#ico_ico_reference_number"
          element :ico_officer_name, "#ico_ico_officer_name"

          element :original_case_number, "#ico_original_case_number"
          element :original_case_number_error, ".js-original-case .error-message"
          section :original_case,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  ".js-original-case-and-friends .js-original-case-report"
          element :link_original_case, :xpath, '//button[contains(.,"Link original case")]'

          element :related_case_number, "#ico_related_case_number"
          element :related_case_number_error, ".js-related-case .error-message"
          section :related_cases,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  ".js-related-case-report"
          element :link_related_case, :xpath, '//button[contains(.,"Link related case")]'

          element :date_received_day, "#ico_received_date_dd"
          element :date_received_month, "#ico_received_date_mm"
          element :date_received_year, "#ico_received_date_yyyy"

          element :external_deadline_day, "#ico_external_deadline_dd"
          element :external_deadline_month, "#ico_external_deadline_mm"
          element :external_deadline_year, "#ico_external_deadline_yyyy"

          element :internal_deadline_day, "#ico_internal_deadline_dd"
          element :internal_deadline_month, "#ico_internal_deadline_mm"
          element :internal_deadline_year, "#ico_internal_deadline_yyyy"

          element :date_draft_compliant_day, "#ico_date_draft_compliant_dd"
          element :date_draft_compliant_month, "#ico_date_draft_compliant_mm"
          element :date_draft_compliant_year, "#ico_date_draft_compliant_yyyy"

          element :case_details, "#ico_message"

          element :dropzone_container, ".dropzone"

          # only shows up when using drop_in_dropzone
          element :uploaded_request_file_input, "#uploadedRequestFileInput"

          element :submit_button, ".button"

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

          def set_draft_deadline_date(draft_deadline_date)
            internal_deadline_day.set(draft_deadline_date.day)
            internal_deadline_month.set(draft_deadline_date.month)
            internal_deadline_year.set(draft_deadline_date.year)
          end

          def add_original_case(kase)
            original_case_number.set kase.number
            link_original_case.click
            has_original_case?
            original_case.has_linked_records?(count: 1)
          end

          def add_related_cases(kases)
            related_case_count = if has_related_cases?
                                   related_cases.linked_records.count
                                 else
                                   0
                                 end
            kases.each do |kase|
              related_case_number.set kase.number
              link_related_case.click
              has_related_cases?
              related_case_count += 1
              related_cases.has_linked_records?(count: related_case_count)
            end
          end

          def fill_in_case_details(params = {})
            kase = FactoryBot.build_stubbed :ico_foi_case, params

            set_received_date(kase.received_date)
            set_draft_deadline_date(kase.internal_deadline)
            set_final_deadline_date(kase.external_deadline)

            ico_officer_name.set kase.ico_officer_name
            ico_reference_number.set kase.ico_reference_number

            case_details.set kase.message
            kase.uploaded_request_files.each do |file|
              drop_in_dropzone(file)
            end

            kase
          end

          def drop_in_dropzone(file_path)
            super file_path:,
                  input_name: dropzone_container["data-file-input-name"],
                  container_selector: "#uploaded-request-files-fields"
          end
        end
      end
    end
  end
end
