module PageObjects
  module Pages
    module Cases
      class NewResponseUploadPage < PageObjects::Pages::Base
        set_url '/cases/{id}/new_response_upload'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :clearance,
                PageObjects::Sections::Cases::ClearanceCopySection, '.clearance-copy'

        element :file_fields, '#uploaded_files'
        element :upload_response_button, '.button'

        # only shows up when using drop_in_dropzone
        element :uploaded_request_file_input, '#uploadedRequestFileInput'

        # Upload a file to Dropzone.js
        def drop_in_dropzone(file_path)
          super file_path: file_path,
                input_name: 'uploaded_files[]',
                container_selector: '.dropzone:first'
        end
      end
    end
  end
end
