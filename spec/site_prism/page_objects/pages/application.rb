module PageObjects
  module Pages
    module Application
      def app
        @app ||= {}
      end

      {
        cases:                     'CasesPage',
        closed_cases:              'Cases::ClosedCasesPage',
        cases_new:                 'Cases::NewPage',
        cases_show:                'Cases::ShowPage',
        cases_close:               'Cases::ClosePage',
        cases_respond:             'Cases::RespondPage',
        cases_new_response_upload: 'Cases::NewResponseUploadPage',
        login:                     'LoginPage',
        assignments_new:           'Assignments::NewPage',
        assignments_edit:          'Assignments::EditPage',
        global_nav_partial:        'Partials::GlobalNavPartial'
      }.each do |page_name, page_class|
        full_page_class = "PageObjects::Pages::#{page_class}"
        define_method "#{page_name}_page" do
          app[page_name] ||= full_page_class.constantize.send :new
        end
      end
    end
  end
end
