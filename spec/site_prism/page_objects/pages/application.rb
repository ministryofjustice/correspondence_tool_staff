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
        approve_response_interstitial:  'Cases::ApproveResponseInterstitialPage',
        approve_response:               'Cases::ApproveResponsePage',
        assign_to_new_team:             'Assignments::AssignToNewTeamPage',
        assignments_edit:               'Assignments::EditPage',
        assignments_new:                'Assignments::NewPage',
        assignment_rejected:            'Assignments::ShowRejectedPage',
        cases:                          'CasesPage',
        cases_close:                    'Cases::ClosePage',
        cases_new:                      'Cases::NewPage',
        cases_new_foi:                  'Cases::New::FOIPage',
        cases_new_sar:                  'Cases::New::SARPage',
        cases_new_case_link:            'Cases::NewCaseLinkPage',
        cases_edit:                     'Cases::EditPage',
        cases_edit_closure:             'Cases::EditClosurePage',
        cases_new_response_upload:      'Cases::NewResponseUploadPage',
        cases_remove_clearance_form:    'Cases::RemoveClearanceFormPage',
        cases_respond:                  'Cases::RespondPage',
        cases_search:                   'Cases::SearchPage',
        cases_show:                     'Cases::ShowPage',
        closed_cases:                   'Cases::ClosedCasesPage',
        confirm_destroy:                'Cases::ConfirmDestroyPage',
        cases_extend_for_pit:           'Cases::ExtendForPITPage',
        global_nav_partial:             'Partials::GlobalNavPartial',
        header_partial:                 'Partials::HeaderPartial',
        incoming_cases:                 'Cases::IncomingCasesPage',
        login:                          'LoginPage',
        my_open_cases:                  'Cases::MyOpenCasesPage',
        open_cases:                     'Cases::OpenCasesPage',
        password:                       'PasswordPage',
        request_amends:                 'Cases::RequestAmendsPage',
        reassign_user:                  'Assignments::ReassignUserPage',
        stats_index:                    'Stats::IndexPage',
        stats_custom:                   'Stats::CustomPage',
        teams_new:                      'Teams::NewPage',
        teams_edit:                     'Teams::EditPage',
        teams_index:                    'Teams::IndexPage',
        teams_areas:                    'Teams::BusinessAreasCoveredPage',
        teams_show:                     'Teams::ShowPage',
        users_index:                    'Users::IndexPage',
        users_new:                      'Users::NewPage',
        users_show:                     'Users::ShowPage',
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
        open_case_status_filter_panel:'Cases::OpenCaseStatusFilterPanelSection',
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
