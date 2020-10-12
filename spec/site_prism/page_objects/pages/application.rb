require 'page_objects/pages/base'

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
        admin_cases:                    'Admin::CasesPage',
        admin_cases_new:                'Admin::Cases::NewPage',
        admin_cases_new_foi:            'Admin::Cases::NewFOIPage',
        admin_cases_new_sar:            'Admin::Cases::NewSARPage',
        admin_cases_new_ico:            'Admin::Cases::NewICOPage',
        admin_cases_new_overturned_sar: 'Admin::Cases::NewOverturnedSARPage',
        admin_cases_new_overturned_foi: 'Admin::Cases::NewOverturnedFOIPage',
        assign_to_new_team:             'Assignments::AssignToNewTeamPage',
        assignments_edit:               'Assignments::EditPage',
        assignments_new:                'Assignments::NewPage',
        assignment_rejected:            'Assignments::ShowRejectedPage',
        cases:                          'CasesPage',
        cases_approve:                  'Cases::ApprovePage',
        cases_close:                    'Cases::ClosePage',
        cases_closure_outcomes:         'Cases::ClosureOutcomesPage',
        cases_new:                      'Cases::NewPage',
        cases_new_foi:                  'Cases::New::FOIPage',
        cases_new_ico:                  'Cases::New::ICOPage',
        cases_new_sar_overturned_ico:   'Cases::New::SarOverturnedIcoPage',
        cases_new_foi_overturned_ico:   'Cases::New::FoiOverturnedIcoPage',
        cases_new_sar:                  'Cases::New::SARPage',
        cases_new_offender_sar_subject_details:                 'Cases::New::OffenderSARPageSubjectDetails',
        cases_new_offender_sar_requester_details:                 'Cases::New::OffenderSARPageRequesterDetails',
        cases_new_offender_sar_recipient_details:                 'Cases::New::OffenderSARPageRecipientDetails',
        cases_new_offender_sar_requested_info:                 'Cases::New::OffenderSARPageRequestedInfo',
        cases_new_offender_sar_request_details:                 'Cases::New::OffenderSARPageRequestDetails',
        cases_new_offender_sar_date_received:                 'Cases::New::OffenderSARPageDateReceived',
        cases_edit_offender_sar_subject_details:                 'Cases::Edit::OffenderSARPageSubjectDetails',
        cases_edit_offender_sar_requester_details:                 'Cases::Edit::OffenderSARPageRequesterDetails',
        cases_edit_offender_sar_requested_info:                 'Cases::Edit::OffenderSARPageRequestedInfo',
        cases_edit_offender_sar_date_responded:                 'Cases::Edit::OffenderSARPageDateResponded',
        cases_edit_offender_sar_date_received:                 'Cases::Edit::OffenderSARPageDateReceived',
        cases_new_offender_sar_complaint_subject_details:                 'Cases::New::OffenderSARComplaintPageSubjectDetails',
        cases_new_offender_sar_complaint_requester_details:                 'Cases::New::OffenderSARComplaintPageRequesterDetails',
        cases_new_offender_sar_complaint_recipient_details:                 'Cases::New::OffenderSARComplaintPageRecipientDetails',
        cases_new_offender_sar_complaint_requested_info:                 'Cases::New::OffenderSARComplaintPageRequestedInfo',
        cases_new_offender_sar_complaint_request_details:                 'Cases::New::OffenderSARComplaintPageRequestDetails',
        cases_new_offender_sar_complaint_date_received:                 'Cases::New::OffenderSARComplaintPageDateReceived',
        cases_new_case_link:            'Cases::NewCaseLinkPage',
        cases_edit:                     'Cases::EditPage',
        cases_edit_ico:                 'Cases::Edit::ICOPage',
        cases_edit_closure:             'Cases::EditClosurePage',
        cases_upload_responses:         'Cases::UploadResponsesPage',
        cases_upload_response_and_approve:
          'Cases::UploadResponseAndApprovePage',
        cases_upload_response_and_return_for_redraft:
          'Cases::UploadResponseAndReturnForRedraftPage',
        cases_remove_clearance_form:    'Cases::RemoveClearanceFormPage',
        cases_respond:                  'Cases::RespondPage',
        cases_search:                   'Cases::SearchPage',
        cases_show:                     'Cases::ShowPage',
        cases_cover:                    'Cases::CoverPage',
        closed_cases:                   'Cases::ClosedCasesPage',
        confirm_destroy:                'Cases::ConfirmDestroyPage',
        cases_extend_for_pit:           'Cases::ExtendForPITPage',
        cases_extend_sar_deadline:      'Cases::ExtendSARDeadlinePage',
        data_request:                   'Cases::DataRequestPage',
        data_request_edit:              'Cases::DataRequestEditPage',
        global_nav_partial:             'Partials::GlobalNavPartial',
        header_partial:                 'Partials::HeaderPartial',
        incoming_cases:                 'Cases::IncomingCasesPage',
        cases_new_letter:               'Cases::NewLetterPage',
        cases_show_letter:              'Cases::ShowLetterPage',
        login:                          'LoginPage',
        my_open_cases:                  'Cases::MyOpenCasesPage',
        open_cases:                     'Cases::OpenCasesPage',
        password:                       'PasswordPage',
        request_amends:                 'Cases::RequestAmendsPage',
        reassign_user:                  'Assignments::ReassignUserPage',
        stats_index:                    'Stats::IndexPage',
        stats_new:                      'Stats::NewPage',
        teams_new:                      'Teams::NewPage',
        teams_edit:                     'Teams::EditPage',
        teams_index:                    'Teams::IndexPage',
        teams_areas:                    'Teams::BusinessAreasCoveredPage',
        teams_move:                     'Teams::MoveToDirectoratePage',
        teams_move_form:                'Teams::MoveToDirectorateFormPage',
        teams_join:                     'Teams::JoinTeamPage',
        teams_join_form:                'Teams::JoinTeamFormPage',
        teams_show:                     'Teams::ShowPage',
        users_index:                    'Users::IndexPage',
        users_new:                      'Users::NewPage',
        users_show:                     'Users::ShowPage',
        users_edit:                     'Users::EditPage',
        users_destroy:                  'Users::DestroyPage',
      }.each do |page_name, page_class|
        full_page_class = "PageObjects::Pages::#{page_class}"

        define_method "#{page_name}_page" do
          app_pages[page_name] ||= full_page_class.constantize.__send__ :new
        end
      end

      {
        cases_what_do_you_want_to_do: 'Cases::WhatDoYouWantToDoSection',
        case_status:                  'Cases::CaseStatusSection',
        case_status_filter_panel:     'Cases::StatusFilterPanelSection',
        linked_cases:                 'Cases::LinkedCasesSection',
        case_request:                 'Cases::CaseRequestSection',
        case_details:                 'Cases::CaseDetailsSection',
        case_history:                 'Cases::CaseHistorySection',
        clearance_levels:             'Cases::ClearanceLevelsSection',
        case_attachments:             'Cases::CaseAttachmentSection',
        clearance_copy:               'Cases::ClearanceCopySection',
        ico_case_details:             'Cases::ICO::CaseDetailsSection',
        ico_close:                    'Cases::ICO::ClosureSection',
        ico_decision:                 'Cases::ICO::ICODecisionSection',
        ico_show:                     'Cases::ICO::ShowSection',
        open_case_status_filter_panel:'Cases::OpenCaseStatusFilterPanelSection',
        overturned_foi_case_details:  'Cases::OverturnedFOI::CaseDetailsSection',
        overturned_ico_new_form:      'Cases::OverturnedICO::NewFormSection',
        overturned_sar_case_details:  'Cases::OverturnedSAR::CaseDetailsSection',
        offender_sar_case_details:    'Cases::OffenderSAR::CaseDetailsSection',
        dropzonejs_preview_template:  'Shared::DropzoneJSPreviewTemplateSection',
        pagination:                   'PaginationSection',
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
