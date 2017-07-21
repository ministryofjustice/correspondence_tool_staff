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
        approve_response:          'Cases::ApproveResponsePage',
        assignments_edit:          'Assignments::EditPage',
        assignments_new:           'Assignments::NewPage',
        cases:                     'CasesPage',
        cases_close:               'Cases::ClosePage',
        cases_new:                 'Cases::NewPage',
        cases_new_response_upload: 'Cases::NewResponseUploadPage',
        cases_respond:             'Cases::RespondPage',
        cases_show:                'Cases::ShowPage',
        closed_cases:              'Cases::ClosedCasesPage',
        global_nav_partial:        'Partials::GlobalNavPartial',
        header_partial:            'Partials::HeaderPartial',
        incoming_cases:            'Cases::IncomingCasesPage',
        login:                     'LoginPage',
        open_cases:                'Cases::OpenCasesPage',
        request_amends:            'Cases::RequestAmendsPage',
      }.each do |page_name, page_class|
        full_page_class = "PageObjects::Pages::#{page_class}"
        define_method "#{page_name}_page" do
          app_pages[page_name] ||= full_page_class.constantize.send :new
        end
      end

      {
        cases_what_do_you_want_to_do: 'Cases::WhatDoYouWantToDoSection',
        case_status:                  'Cases::CaseStatusSection',
        case_request:                 'Cases::CaseRequestSection',
        case_details:                 'Cases::CaseDetailsSection',
        case_attachments:             'Cases::CaseAttachmentSection',
        clearance_copy:               'Cases::ClearanceCopySection',
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
