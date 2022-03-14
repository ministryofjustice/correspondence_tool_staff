module PageObjects
  module Pages
    module Cases

      class ICOFOIRecordFurtherActionPage < PageObjects::Pages::Base
        include SitePrism::Support::DropInDropzone

        set_url '/cases/ico_fois/{id}/record_further_action'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection,
                '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                '.page-heading'

        element :request_detail_message, '#ico_message'

        element :dropzone_container, '.dropzone'
        element :file_fields, '#uploaded_request_files'
        element :upload_requests_button, '.button'

        # only shows up when using drop_in_dropzone
        element :uploaded_request_file_input, '#uploadedRequestFileInput'
        elements :uploaded_request_file_inputs, 'input.case-uploaded-files', visible: false

        def fill_in_message(message)
          request_detail_message.set(message)
        end

        # Upload a file to Dropzone.js
        def drop_in_dropzone(file_path)
          super file_path: file_path,
                input_name: 'uploaded_request_files[]',
                container_selector: '.dropzone:first'
        end

      end

    end
  end
end
