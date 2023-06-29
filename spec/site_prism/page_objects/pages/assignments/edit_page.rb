module PageObjects
  module Pages
    module Assignments
      class EditPage < SitePrism::Page
        set_url "/cases/{case_id}/assignments/{id}/edit"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :ico,
                PageObjects::Sections::Cases::ICO::ShowSection,
                "#case-ico"

        section :overturned_sar,
                PageObjects::Sections::Cases::OverturnedSAR::ShowSection,
                "#case-overturned_sar"

        section :overturned_foi,
                PageObjects::Sections::Cases::OverturnedFOI::ShowSection,
                "#case-overturned_foi"

        section :case_status,
                PageObjects::Sections::Cases::CaseStatusSection, ".case-status"

        section :ico_decision_section,
                PageObjects::Sections::Cases::ICO::ICODecisionSection, ".ico-decision-section"

        section :case_details,
                PageObjects::Sections::Cases::CaseDetailsSection, ".case-details"

        element :message_label, ".request--heading"
        element :message, ".request--message p:first"

        section :request,
                PageObjects::Sections::Cases::CaseRequestSection, ".request"

        sections :messages, "#messages-section .message" do
          element :body, ".message-body"
          element :audit, ".message-audit"
        end

        section :new_message, ".message-form" do
          element :input, "textarea"
          element :add_button, ".button"
        end

        section :case_history,
                PageObjects::Sections::Cases::CaseHistorySection, "#case-history"

        section :original_case_details, ".original-case-details" do
          element :link_to_case, "a"
        end

        element :accept_radio, 'label[for="assignment_state_accepted"]'

        element :reject_radio, 'label[for="assignment_state_rejected"]'

        element :confirm_button, '.button[value="Confirm"]'
      end
    end
  end
end
