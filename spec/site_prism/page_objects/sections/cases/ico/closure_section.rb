module PageObjects
  module Sections
    module Cases
      module ICO
        class ClosureSection < SitePrism::Section
          include SitePrism::Support::DropInDropzone

          section :ico_decision, ".ico-decision" do
            element :overturned, "#ico_ico_decision_overturned"
            element :overturned_label, 'label[for="ico_ico_decision_overturned"]'
            element :upheld, "#ico_ico_decision_upheld"
            element :upheld_label, 'label[for="ico_ico_decision_upheld"]'
          end

          element :date_ico_decision_received_day, :case_form_element, "date_ico_decision_received_dd"
          element :date_ico_decision_received_month, :case_form_element, "date_ico_decision_received_mm"
          element :date_ico_decision_received_year, :case_form_element, "date_ico_decision_received_yyyy"

          section :uploads, "#uploaded-ico-decision-files-fields" do
            element :label, "span.form-label-bold"
            element :hint, "span.form-hint"
          end
          section :missing_info, ".missing-info" do
            element :yes, 'label[for="sar_missing_info_yes"]'
            element :no, 'label[for="sar_missing_info_no"]'
          end

          # only shows up when using drop_in_dropzone
          element :uploaded_request_file_input, "#uploadedRequestFileInput"

          # Upload a file to Dropzone.js
          def drop_in_dropzone(file_path)
            super file_path:,
                  input_name: "ico[uploaded_ico_decision_files][]",
                  container_selector: ".dropzone:first"
          end
        end
      end
    end
  end
end
