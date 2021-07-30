
module PageObjects
  module Pages
    module Contacts
      class EditPage < PageObjects::Pages::Base
        include SitePrism::Support::AssignToBusinessUnitHelpers

        set_url '/contacts/{contact_id}/edit'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :name, '#contact_name'
        element :address_line_1, '#contact_address_line_1'
        element :address_line_2, '#contact_address_line_2'
        element :town, '#contact_town'
        element :county, '#contact_county'
        element :postcode, '#contact_postcode'
        element :contact_type, '#countact_contact_type'

        element :submit, '.button'

        def edit_contact(details)
          name.set details[:name] if details[:name]
          address_line_1.set details[:address_line_1] if details[:address_line_1]
          address_line_2.set details[:address_line_2] if details[:address_line_2]
          town.set details[:town] if details[:town]
          county.set details[:county] if details[:county]
          postcode.set details[:postcode] if details[:postcode]
          set_contact_type(details[:contact_type])
        end

        private
        def set_contact_type(contact_type)
          return unless contact_type
          case contact_type
          when 'prison'
            choose 'contact_contact_type_prison', visible: false
          when 'probation'
            choose 'contact_contact_type_probation', visible: false
          when 'solicitor'
            choose 'contact_contact_type_solicitor', visible: false
          else
            return
          end
        end
      end
    end
  end
end
