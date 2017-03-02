module PageObjects
  module Pages
    module Cases
      class NewResponseUploadPage < SitePrism::Page
        set_url '/cases/{id}/new_response_upload'

        element :file_fields, '#uploaded_files'
      end
    end
  end
end
