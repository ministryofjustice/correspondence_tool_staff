module PageObjects
  module Pages
    module Cases
      class NewResponseUploadPage < SitePrism::Page
        set_url '/cases/{id}/new_response_upload'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        element :file_fields, '#uploaded_files'
        element :upload_response_button, '.button'
      end
    end
  end
end
