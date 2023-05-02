module PageObjects
  module Pages
    module Cases
      class DataRequestEmailConfirmationPage < SitePrism::Page
        set_url '/cases/{case_id}/data_requests/{id}/send_email'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :commissioning_document, '.commissioning-document' do  
          section :data, '.grid-row.data-request' do
            element :email, '.data-request__email'
          end  
        end  
         
        element :button_send_email, '.data_request_send_email'
        
      end
    end
  end
end
