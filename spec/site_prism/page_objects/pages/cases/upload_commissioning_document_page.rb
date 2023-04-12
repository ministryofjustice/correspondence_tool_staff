module PageObjects
  module Pages
    module Cases
      class UploadCommissioningDocumentPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{data_request_id}/commissioning_documents/{id}/replace'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :form, '.edit_commissioning_document' do
          element :choose_file, 'button-secondary'
          element :submit_button, '.button'
        end
      end
    end
  end
end
