module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageComplaintType < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/complaint-type"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :ico_contact_name, "#offender_sar_complaint_ico_contact_name"
          element :ico_contact_email, "#offender_sar_complaint_ico_contact_email"
          element :ico_contact_phone, "#offender_sar_complaint_ico_contact_phone"
          element :ico_reference, "#offender_sar_complaint_ico_reference"

          element :gld_contact_name, "#offender_sar_complaint_gld_contact_name"
          element :gld_contact_email, "#offender_sar_complaint_gld_contact_email"
          element :gld_contact_phone, "#offender_sar_complaint_gld_contact_phone"
          element :gld_reference, "#offender_sar_complaint_gld_reference"

          element :submit_button, ".button"

          def fill_in_case_details(params = {})
            kase = FactoryBot.build_stubbed :offender_sar_complaint, params

            fill_in_complaint_type(kase)
            fill_in_complaint_subtype(kase)
            fill_in_priority(kase)
          end

          def fill_in_complaint_type(kase)
            if kase.standard_complaint?
              choose("offender_sar_complaint_complaint_type_standard_complaint", visible: false)
            elsif kase.ico_complaint?
              choose("offender_sar_complaint_complaint_type_ico_complaint", visible: false)
              ico_contact_name.set "Jane Doe ICO"
              ico_contact_email.set "jane_doe_ico@example.com"
              ico_contact_phone.set "01234 567 9876"
              ico_reference.set "ICOREF001Z"
            elsif kase.litigation_complaint?
              choose("offender_sar_complaint_complaint_type_litigation_complaint", visible: false)
              gld_contact_name.set "Priya Singh Litigation"
              gld_contact_email.set "priya_singh_litigation@example.com"
              gld_contact_phone.set "01234 824 9876"
              gld_reference.set "LITREF732K"
            end
          end

          def fill_in_complaint_subtype(kase)
            possible_subtypes = Case::SAR::OffenderComplaint.complaint_subtypes.keys

            possible_subtypes.each do |subtype|
              if kase.send("#{subtype}?".to_sym)
                choose("offender_sar_complaint_complaint_subtype_#{subtype}", visible: false)
              end
            end
          end

          def fill_in_priority(kase)
            if kase.normal_priority?
              choose("offender_sar_complaint_priority_normal", visible: false)
            elsif kase.high_priority?
              choose("offender_sar_complaint_priority_high", visible: false)
            end
          end
        end
      end
    end
  end
end
