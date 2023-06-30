module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARComplaintPageComplaintType < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/{id}/edit/complaint_type"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :standard_radio_button, "#offender_sar_complaint_complaint_type_standard_complaint"

          element :ico_radio_button, "#offender_sar_complaint_complaint_type_ico_complaint"
          element :ico_contact_name, "#offender_sar_complaint_ico_contact_name"
          element :ico_contact_email, "#offender_sar_complaint_ico_contact_email"
          element :ico_contact_phone, "#offender_sar_complaint_ico_contact_phone"
          element :ico_contact_reference, "#offender_sar_complaint_ico_reference"

          element :gld_radio_button, "#offender_sar_complaint_complaint_type_litigation_complaint"
          element :gld_contact_name, "#offender_sar_complaint_gld_contact_name"
          element :gld_contact_email, "#offender_sar_complaint_gld_contact_email"
          element :gld_contact_phone, "#offender_sar_complaint_gld_contact_phone"
          element :gld_contact_reference, "#offender_sar_complaint_gld_reference"

          element :submit_button, ".button"

          def edit_complaint_type(new_type, options = {})
            case new_type
            when "ico"
              ico_radio_button.set(true)
              ico_contact_name.set(options[:name])
              ico_contact_email.set(options[:email])
              ico_contact_phone.set(options[:phone])
              ico_contact_reference.set(options[:reference])
            when "litigation"
              gld_radio_button.set(true)
              gld_contact_name.set(options[:name])
              gld_contact_email.set(options[:email])
              gld_contact_phone.set(options[:phone])
              gld_contact_reference.set(options[:reference])
            else
              standard_radio_button.set(true)
            end
          end
        end
      end
    end
  end
end
