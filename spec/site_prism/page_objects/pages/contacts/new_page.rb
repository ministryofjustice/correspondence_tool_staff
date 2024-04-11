module PageObjects
  module Pages
    module Contacts
      class NewPage < PageObjects::Pages::Base
        include SitePrism::Support::AssignToBusinessUnitHelpers

        set_url "/contacts/new"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :contact_type, "#contact_type"

        element :submit, ".button"

        def new_contact(details)
          set_contact_type(details[:contact_type])
        end

        def set_contact_type(contact_type)
          return unless contact_type

          case contact_type
          when "prison"
            choose "Prison", visible: false
          when "probation"
            choose "Probation", visible: false
          when "solicitor"
            choose "Solicitor", visible: false
          end
        end
      end
    end
  end
end
