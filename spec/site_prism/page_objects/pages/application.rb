require "page_objects/pages/base"

module PageObjects
  module Pages
    module Application
      def app_pages
        @app_pages ||= {}
      end

      def app_sections
        @app_sections ||= {}
      end

      {
        admin_cases: "Admin::CasesPage",
        admin_cases_new: "Admin::Cases::NewPage",
        admin_cases_new_foi: "Admin::Cases::NewFOIPage",
        admin_cases_new_sar: "Admin::Cases::NewSARPage",
        admin_cases_new_ico: "Admin::Cases::NewICOPage",
        admin_cases_new_overturned_sar: "Admin::Cases::NewOverturnedSARPage",
        admin_cases_new_overturned_foi: "Admin::Cases::NewOverturnedFOIPage",
        assign_to_new_team: "Assignments::AssignToNewTeamPage",
        assignments_edit: "Assignments::EditPage",
        assignments_new: "Assignments::NewPage",
        assignment_rejected: "Assignments::ShowRejectedPage",
        cases: "CasesPage",
        cases_approve: "Cases::ApprovePage",
        cases_close: "Cases::ClosePage",
        cases_closure_outcomes: "Cases::ClosureOutcomesPage",
        cases_new: "Cases::NewPage",
        cases_new_foi: "Cases::New::FOIPage",
        cases_new_ico: "Cases::New::ICOPage",
        cases_new_sar_overturned_ico: "Cases::New::SAROverturnedICOPage",
        cases_new_foi_overturned_ico: "Cases::New::FOIOverturnedICOPage",
        cases_new_sar: "Cases::New::SARPage",

        cases_ico_require_further_action: "Cases::ICORequireFurtherActionPage",
        cases_ico_record_further_action: "Cases::ICORecordFurtherActionPage",

        case_new_sar_ir_link_case: "Cases::New::SARInternalReviewLinkCasePage",
        case_new_sar_ir_confirm_sar: "Cases::New::SARInternalReviewConfirmSARCasePage",
        case_new_sar_ir_case_details: "Cases::New::SARInternalReviewCaseDetailsPage",

        cases_new_offender_sar_subject_details: "Cases::New::OffenderSARPageSubjectDetails",
        cases_new_offender_sar_reason_rejected: "Cases::New::OffenderSARPageReasonRejected",
        cases_new_offender_sar_requester_details: "Cases::New::OffenderSARPageRequesterDetails",
        cases_new_offender_sar_recipient_details: "Cases::New::OffenderSARPageRecipientDetails",
        cases_new_offender_sar_requested_info: "Cases::New::OffenderSARPageRequestedInfo",
        cases_new_offender_sar_request_details: "Cases::New::OffenderSARPageRequestDetails",
        cases_new_offender_sar_date_received: "Cases::New::OffenderSARPageDateReceived",
        cases_edit_offender_sar_subject_details: "Cases::Edit::OffenderSARPageSubjectDetails",
        cases_edit_offender_sar_requester_details: "Cases::Edit::OffenderSARPageRequesterDetails",
        cases_edit_offender_sar_requested_info: "Cases::Edit::OffenderSARPageRequestedInfo",
        cases_edit_offender_sar_date_responded: "Cases::Edit::OffenderSARPageDateResponded",
        cases_edit_offender_sar_date_received: "Cases::Edit::OffenderSARPageDateReceived",
        cases_edit_offender_sar_move_back: "Cases::Edit::OffenderSARPageMoveCaseBack",
        cases_edit_offender_sar_reason_for_lateness: "Cases::Edit::OffenderSARPageRecordReasonForLateness",
        cases_edit_offender_sar_sent_to_sscl: "Cases::Edit::OffenderSARPageSentToSscl",
        cases_edit_offender_sar_accepted_date_received: "Cases::Edit::OffenderSARAcceptedDateReceived",
        cases_edit_offender_sar_reason_rejected: "Cases::Edit::OffenderSARPageReasonRejected",

        cases_new_offender_sar_complaint_confirm_case: "Cases::New::OffenderSARComplaintPageConfirmCase",
        cases_new_offender_sar_complaint_link_offender_sar: "Cases::New::OffenderSARComplaintPageLinkSARCase",
        cases_new_offender_sar_complaint_complaint_type: "Cases::New::OffenderSARComplaintPageComplaintType",
        cases_new_offender_sar_complaint_requester_details: "Cases::New::OffenderSARComplaintPageRequesterDetails",
        cases_new_offender_sar_complaint_recipient_details: "Cases::New::OffenderSARComplaintPageRecipientDetails",
        cases_new_offender_sar_complaint_requested_info: "Cases::New::OffenderSARComplaintPageRequestedInfo",
        cases_new_offender_sar_complaint_request_details: "Cases::New::OffenderSARComplaintPageRequestDetails",
        cases_new_offender_sar_complaint_date_received: "Cases::New::OffenderSARComplaintPageDateReceived",
        cases_new_offender_sar_complaint_external_deadline: "Cases::New::OffenderSARComplaintPageExternalDeadline",

        cases_edit_offender_sar_complaint_type: "Cases::Edit::OffenderSARComplaintPageComplaintType",
        cases_edit_offender_sar_complaint_date_received: "Cases::Edit::OffenderSARComplaintPageDateReceived",

        cases_edit_offender_sar_complaint_appeal_outcome: "Cases::Edit::OffenderSARComplaintPageAppealOutcome",
        cases_edit_offender_sar_complaint_outcome: "Cases::Edit::OffenderSARComplaintPageOutcome",
        cases_edit_offender_sar_complaint_costs: "Cases::Edit::OffenderSARComplaintPageCosts",
        cases_edit_offender_sar_complaint_approval_flags: "Cases::Edit::OffenderSARComplaintPageApprovalFlags",
        cases_edit_offender_sar_complaint_reopen: "Cases::Edit::OffenderSARComplaintPageReopen",
        cases_edit_offender_sar_complaint_date_responded: "Cases::Edit::OffenderSARComplaintPageDateResponded",
        cases_edit_offender_sar_complaint_external_deadline: "Cases::Edit::OffenderSARComplaintPageExternalDeadline",
        cases_edit_offender_sar_complaint_requested_info: "Cases::Edit::OffenderSARComplaintPageRequestedInfo",
        cases_edit_offender_sar_complaint_requester_details: "Cases::Edit::OffenderSARComplaintPageRequesterDetails",
        cases_edit_offender_sar_complaint_subject_details: "Cases::Edit::OffenderSARComplaintPageSubjectDetails",
        cases_edit_offender_sar_complaint: "Cases::Edit::OffenderSARComplaintPageEdit",

        cases_new_case_link: "Cases::NewCaseLinkPage",
        cases_edit: "Cases::EditPage",
        cases_edit_ico: "Cases::Edit::ICOPage",
        cases_edit_closure: "Cases::EditClosurePage",
        cases_upload_requests: "Cases::UploadRequestsPage",
        cases_upload_responses: "Cases::UploadResponsesPage",
        cases_upload_response_and_approve:
          "Cases::UploadResponseAndApprovePage",
        cases_upload_response_and_return_for_redraft:
          "Cases::UploadResponseAndReturnForRedraftPage",
        cases_remove_clearance_form: "Cases::RemoveClearanceFormPage",
        cases_respond: "Cases::RespondPage",
        cases_search: "Cases::SearchPage",
        cases_show: "Cases::ShowPage",
        case_send_back: "Cases::SendBackPage",
        cases_cover: "Cases::CoverPage",
        contacts_edit: "Contacts::EditPage",
        contacts_index: "Contacts::IndexPage",
        contacts_new: "Contacts::NewPage",
        contacts_new_details: "Contacts::NewDetailsPage",
        closed_cases: "Cases::ClosedCasesPage",
        confirm_destroy: "Cases::ConfirmDestroyPage",
        cases_extend_for_pit: "Cases::ExtendForPITPage",
        cases_extend_sar_deadline: "Cases::ExtendSARDeadlinePage",
        cases_stop_the_clock: "Cases::StopTheClockPage",
        data_request: "Cases::DataRequestPage",
        data_request_area: "Cases::DataRequestAreaPage",
        data_request_area_show: "Cases::DataRequestAreaShowPage",
        data_request_edit: "Cases::DataRequestEditPage",
        data_request_show: "Cases::DataRequestShowPage",
        data_request_send_probation_email:
          "Cases::DataRequestProbationEmailPage",
        data_request_area_email_confirmation: "Cases::DataRequestAreaEmailConfirmationPage",
        new_commissioning_document: "Cases::NewCommissioningDocumentPage",
        edit_commissioning_document: "Cases::EditCommissioningDocumentPage",
        upload_commissioning_document: "Cases::UploadCommissioningDocumentPage",
        global_nav_partial: "Partials::GlobalNavPartial",
        header_partial: "Partials::HeaderPartial",
        incoming_cases: "Cases::IncomingCasesPage",
        cases_new_letter: "Cases::NewLetterPage",
        cases_show_letter: "Cases::ShowLetterPage",
        login: "LoginPage",
        my_open_cases: "Cases::MyOpenCasesPage",
        open_cases: "Cases::OpenCasesPage",
        password: "PasswordPage",
        request_amends: "Cases::RequestAmendsPage",
        reassign_user: "Assignments::ReassignUserPage",
        assign_to_team_member: "Assignments::AssignToTeamMemberPage",
        stats_index: "Stats::IndexPage",
        stats_new: "Stats::NewPage",
        teams_new: "Teams::NewPage",
        teams_edit: "Teams::EditPage",
        teams_index: "Teams::IndexPage",
        teams_areas: "Teams::BusinessAreasCoveredPage",
        teams_move: "Teams::MoveToDirectoratePage",
        teams_move_form: "Teams::MoveToDirectorateFormPage",
        teams_join: "Teams::JoinTeamPage",
        teams_join_form: "Teams::JoinTeamFormPage",
        teams_show: "Teams::ShowPage",
        directorates_move: "Teams::MoveToBusinessGroupPage",
        users_index: "Users::IndexPage",
        users_new: "Users::NewPage",
        users_show: "Users::ShowPage",
        users_edit: "Users::EditPage",
        users_destroy: "Users::DestroyPage",
      }.each do |page_name, page_class|
        full_page_class = "PageObjects::Pages::#{page_class}"

        define_method "#{page_name}_page" do
          app_pages[page_name] ||= full_page_class.constantize.__send__ :new
        end
      end

      {
        cases_what_do_you_want_to_do: "Cases::WhatDoYouWantToDoSection",
        case_status: "Cases::CaseStatusSection",
        case_status_filter_panel: "Cases::StatusFilterPanelSection",
        linked_cases: "Cases::LinkedCasesSection",
        case_request: "Cases::CaseRequestSection",
        case_details: "Cases::CaseDetailsSection",
        case_history: "Cases::CaseHistorySection",
        clearance_levels: "Cases::ClearanceLevelsSection",
        case_attachments: "Cases::CaseAttachmentSection",
        clearance_copy: "Cases::ClearanceCopySection",
        ico_case_details: "Cases::ICO::CaseDetailsSection",
        ico_close: "Cases::ICO::ClosureSection",
        ico_decision: "Cases::ICO::ICODecisionSection",
        ico_show: "Cases::ICO::ShowSection",
        open_case_status_filter_panel: "Cases::OpenCaseStatusFilterPanelSection",
        overturned_foi_case_details: "Cases::OverturnedFOI::CaseDetailsSection",
        overturned_ico_new_form: "Cases::OverturnedICO::NewFormSection",
        overturned_sar_case_details: "Cases::OverturnedSAR::CaseDetailsSection",
        offender_sar_case_details: "Cases::OffenderSAR::CaseDetailsSection",
        dropzonejs_preview_template: "Shared::DropzoneJSPreviewTemplateSection",
        pagination: "PaginationSection",
      }.each do |section_name, section_class|
        full_section_class = "PageObjects::Sections::#{section_class}"
        define_method "#{section_name}_section" do |rendered|
          app_sections[section_name] ||=
            full_section_class.constantize.send :new,
                                                nil,
                                                Capybara.string(rendered)
        end
      end
    end
  end
end
