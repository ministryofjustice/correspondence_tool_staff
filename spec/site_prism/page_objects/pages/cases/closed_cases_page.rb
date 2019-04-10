module PageObjects
  module Pages
    module Cases
      class ClosedCasesPage < SitePrism::Page
        set_url '/cases/closed_cases'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :closed_case_report, '.closed-case-report' do
          element :heading_row, 'thead'
          section :table_body, 'tbody' do
            sections :closed_case_rows, 'tr' do
              element :case_number, 'td:nth-child(1)'
              element :case_type, 'td:nth-child(2)'
              section :subject_name, 'td:nth-child(3)' do
                element :name, 'strong'
                element :subject, 'span'
              end
            end
          end
        end

        element :download_deleted_cases_link, 'a:contains("Download deleted cases")'
      end
    end
  end
end
