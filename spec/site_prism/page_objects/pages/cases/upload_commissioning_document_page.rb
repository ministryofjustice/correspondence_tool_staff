module PageObjects
  module Pages
    module Cases
      class UploadCommissioningDocumentPage < PageObjects::Pages::Base
        include SitePrism::Support::DropInDropzone

        set_url '/cases/{case_id}/data_requests/{data_request_id}/commissioning_documents/{id}/replace'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :dropzone_container, '.dropzone'
        element :file_fields, '#upload'
        element :upload_document_button, '.button'

        # only shows up when using drop_in_dropzone
        element :uploaded_request_file_input, '#uploadedRequestFileInput'

        # Upload a file to Dropzone.js
        def drop_in_dropzone(file_path)
          super file_path: file_path,
                input_name: 'commissioning_document[upload][]',
                container_selector: '.dropzone:first'
        end
      end
    end
  end
end
