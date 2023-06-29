module PageObjects
  module Pages
    module Admin
      module Cases
        class NewFOIPage < PageObjects::Pages::Base
          set_url "/admin/cases/new/foi"

          sections :notices, ".notice-summary" do
            element :heading, ".notice-summary-heading"
          end

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :case_type_foi_standard, "#case_foi_type_casefoistandard"

          element :full_name, "#case_foi_name"
          element :email, "#case_foi_email"
          element :address, "#case_foi_postal_address"
          element :type_of_requester, :xpath,
                  '//fieldset[contains(.,"Type of requester")]'
          element :subject, "#case_foi_subject"
          element :full_request, "#case_foi_message"
          element :received_date, "#case_foi_received_date"
          element :created_at, "#case_foi_created_at"

          element :flag_for_disclosure_specialists,
                  "#case_foi_flagged_for_disclosure_specialist_clearance"
          element :flag_for_press_office,
                  "#case_foi_flagged_for_press_office_clearance"
          element :flag_for_private_office,
                  "#case_foi_flagged_for_private_office_clearance"

          element :target_state, "#case_foi_target_state"

          element :submit_button, ".button"
        end
      end
    end
  end
end
