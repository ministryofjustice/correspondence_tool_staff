module PageObjects
  module Pages
    module Cases
      class CommissioningDocumentPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{id}/commissioning_documents/new'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :form, '#new_commissioning_document' do
          element :template, :xpath, '//fieldset[contains(.,"Which data request document would you like to use")]'
          element :submit_button, '.button'
        end
      end
    end
  end
end
