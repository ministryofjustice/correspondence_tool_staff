module PageObjects
  module Pages
    module Contacts
      class NewPage < PageObjects::Pages::Base
        include SitePrism::Support::AssignToBusinessUnitHelpers

        set_url "/contacts/new"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :name, "#contact_name"
        element :address_line_1, "#contact_address_line_1"
        element :address_line_2, "#contact_address_line_2"
        element :town, "#contact_town"
        element :county, "#contact_county"
        element :postcode, "#contact_postcode"
        element :data_request_name, "#contact_data_request_name"
        element :data_request_emails, "#contact_data_request_emails"

        element :submit, ".button"

        def new_contact(details)
          name.set details[:name] if details[:name]
          address_line_1.set details[:address_line_1] if details[:address_line_1]
          address_line_2.set details[:address_line_2] if details[:address_line_2]
          town.set details[:town] if details[:town]
          county.set details[:county] if details[:county]
          postcode.set details[:postcode] if details[:postcode]
        end
      end
    end
  end
end
