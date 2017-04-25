module PageObjects
  module Pages
    module Cases
      class ClosedCasesPage < SitePrism::Page
        set_url '/cases/closed_cases'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        element :heading, 'h1.heading-xlarge'

        section :closed_case_report, '.closed-case-report' do
          element :heading_row, 'thead'
          section :table_body, 'tbody' do
            sections :closed_case_rows, 'tr' do
              element :case_number, 'td:nth-child(1)'
              section :subject_name, 'td:nth-child(2)' do
                element :name, 'strong'
                element :subject, 'span'
              end
            end
          end
        end

      end
    end
  end
end
