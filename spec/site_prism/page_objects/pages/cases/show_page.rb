module PageObjects
  module Pages
    module Cases
      class ShowPage < SitePrism::Page
        set_url "/cases/{id}"

        section :user_card, PageObjects::Sections::UserCardSection, ".user-card"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        element :happy_action_notice, ".alert-green"
        element :escalation_notice, ".alert-orange"
        element :notice, ".notice-summary-heading"
        element :alert, ".error-summary-heading"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :actions, ".button-holder" do
          element :send_back, "#action--send-back"
          element :assign_to_new_team, "#action--assign-new-team"
          element :upload_response, "#action--upload-response"
          element :create_overturned, "#action--create-overturned"
          element :mark_as_sent, "#action--mark-response-as-sent"
          element :close_case, "#action--close-case"
          element :clear_case, "#action--approve"
          element :request_amends, "#action--request-amends"
          element :upload_approve, "#action--upload-approve"
          element :upload_redraft, "#action--upload-redraft"
          element :reassign_user, "#action--reassign-case"
          element :assign_to_team_member, "#action--assign-to-team-member"
          element :mark_as_sent_and_close, "#action--mark-response-as-sent-and-close"
          element :progress_to_disclosure, "#action--progress-for-clearance"
          element :mark_as_waiting_for_data, "#action--mark-as-waiting-for-data"
          element :mark_as_ready_for_vetting, "#action--mark-as-ready-for-vetting"
          element :mark_as_vetting_in_progress, "#action--mark-as-vetting-in-progress"
          element :mark_as_ready_to_copy, "#action--mark-as-ready-to-copy"
          element :mark_as_ready_to_dispatch, "#action--mark-as-ready-to-dispatch"
          element :require_further_action, "#action--record_further_action"
        end
        element :extend_for_pit_action, "#action--extend-for-pit"
        element :remove_pit_extension_action, "#action--remove-pit-extension"
        element :remove_sar_deadline_extension, "#action--remove-extended-deadline-for-sar"
        element :extend_sar_deadline, "#action--extend-deadline-for-sar"
        element :stop_the_clock, "#action--stop-the-clock"
        element :restart_the_clock, "#action--restart-the-clock"

        section :case_status,
                PageObjects::Sections::Cases::CaseStatusSection, ".case-status"

        section :data_request_areas,
                PageObjects::Sections::Cases::DataRequestAreasSection, ".data-request-areas"

        section :data_request_area_actions, ".data-request-area-buttons" do
          element :record_data_request_area, "#action--record-data-request-area"
        end

        section :flags_items, ".multiple-choice" do
          element :partial_case_flag, "#is_partial_case"
        end

        section :link_case,
                PageObjects::Sections::Cases::LinkedCasesSection, ".case-linking"

        section :case_details,
                PageObjects::Sections::Cases::CaseDetailsSection, ".case-details"

        section :clearance_levels,
                PageObjects::Sections::Cases::ClearanceLevelsSection, ".clearance-details"

        section :request,
                PageObjects::Sections::Cases::CaseRequestSection, ".request"

        sections :case_attachments,
                 PageObjects::Sections::Cases::CaseAttachmentSection,
                 ".case-attachments .case-attachments-group"

        section :what_do_you_want_to_do,
                PageObjects::Sections::Cases::WhatDoYouWantToDoSection,
                ".what-do-you-want-to-do"

        section :ico,
                PageObjects::Sections::Cases::ICO::ShowSection,
                "#case-ico"

        sections :messages, "#messages-section .message" do
          element :body, ".message-body"
          element :audit, ".message-audit"
        end

        section :new_message, ".message-form" do
          element :input, "textarea"
          element :add_button, ".button"
        end

        section :offender_sar_subject_details, ".section-subject-details" do
          element :change_link, "a"
        end

        section :offender_sar_complaint_type, ".section-complaint-type" do
          element :change_link, "a"
        end

        section :offender_sar_requester_details, ".section-requester-details" do
          element :change_link, "a"
        end

        section :offender_sar_reason_rejected, ".section-rejected-reasons" do
          element :change_link, "a"
        end

        section :offender_sar_requested_info, ".section-requested-heading" do
          element :change_link, "a"
        end

        section :offender_sar_date_received, ".section-date-received" do
          element :change_link, "a"
        end

        section :offender_sar_external_deadline, ".section-external-deadline" do
          element :change_link, "a"
        end

        section :offender_sar_complaint_approval_flags, ".section-approval-flags" do
          element :change_link, "a"
        end

        section :offender_sar_complaint_appeal_outcome, ".section-appeal-outcome" do
          element :change_link, "a"
        end

        section :offender_sar_complaint_outcome, ".section-outcome" do
          element :change_link, "a"
        end

        section :offender_sar_complaint_costs, ".section-costs" do
          element :change_link, "a"
        end

        section :offender_sar_reason_for_lateness, ".section-reason-for-lateness" do
          element :change_link, "a"
        end

        section :offender_sar_sent_to_sscl, ".section-sent-to-sscl" do
          element :change_link, "a"
        end

        element :offender_sar_complaint_subtype, ".section-complaint-subtype"
        element :offender_sar_complaint_priority, ".section-complaint-priority"
        element :offender_sar_complaint_ico_contact_name, ".section-ico-contact-name"
        element :offender_sar_complaint_ico_contact_email, ".section-ico-contact-email"
        element :offender_sar_complaint_ico_contact_phone, ".section-ico-contact-phone"
        element :offender_sar_complaint_ico_reference, ".section-ico-reference"
        element :offender_sar_complaint_gld_contact_name, ".section-gld-contact-name"
        element :offender_sar_complaint_gld_contact_email, ".section-gld-contact-email"
        element :offender_sar_complaint_gld_contact_phone, ".section-gld-contact-phone"
        element :offender_sar_complaint_gld_reference, ".section-gld-reference"

        section :case_history,
                PageObjects::Sections::Cases::CaseHistorySection, "#case-history"

        element :delete_case, 'a:contains("Delete case")'

        def collection_for_case_attachment(file)
          case_attachments.each do |case_attachment|
            case_attachment.collection.each do |collection|
              return collection if collection.filename.text == file
            end
          end
          nil
        end

        def add_message_to_case(message)
          new_message.input.set message
          new_message.add_button.click
        end
      end
    end
  end
end
