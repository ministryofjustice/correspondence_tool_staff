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
        cases:                     'CasesPage',
        closed_cases:              'Cases::ClosedCasesPage',
        incoming_cases:            'Cases::IncomingCasesPage',
        cases_new:                 'Cases::NewPage',
        cases_show:                'Cases::ShowPage',
        cases_close:               'Cases::ClosePage',
        cases_respond:             'Cases::RespondPage',
        cases_new_response_upload: 'Cases::NewResponseUploadPage',
        login:                     'LoginPage',
        assignments_new:           'Assignments::NewPage',
        assignments_edit:          'Assignments::EditPage',
        global_nav_partial:        'Partials::GlobalNavPartial',
        header_partial:            'Partials::HeaderPartial'
      }.each do |page_name, page_class|
        full_page_class = "PageObjects::Pages::#{page_class}"
        define_method "#{page_name}_page" do
          app_pages[page_name] ||= full_page_class.constantize.send :new
        end
      end

      {
        cases_what_do_you_want_to_do: 'Cases::WhatDoYouWantToDoSection',
        case_status:                  'Cases::CaseStatusSection',
        case_details:                 'Cases::CaseDetailsSection',
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
