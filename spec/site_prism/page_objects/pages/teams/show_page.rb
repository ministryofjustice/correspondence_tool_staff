module PageObjects
  module Pages
    module Teams
      class ShowPage < SitePrism::Page
        set_url '/teams/{id}'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :flash_notice, '.notice-summary'
        element :flash_alert, '.error-summary'

        element :heading, 'h1.page-heading'
        element :deputy_director, '.team-lead-title'
        element :director, 'h2:first'
        element :director_general, 'h2:first'
        element :team_email, '.team-email'


        sections :directorates_list, '.report tbody tr' do
          element :name, 'td[aria-label="Name"] a'
          element :director, 'td[aria-label="Director"]'
          element :num_business_units, 'td[aria-label="Business units"]'
          element :actions, 'td[aria-label="Actions"]'
        end

        sections :business_units_list, '.report tbody tr' do
          element :name, 'td[aria-label="Name"] a'
          element :deputy_director, 'td[aria-label="Deputy director"]'
          element :email, 'td[aria-label="Email"]'
          element :num_responders,
                  'td[aria-label="Information officers"]'
          element :edit, 'a.action--edit'
        end

        sections :information_officers_list, '.report tbody tr' do
          element :name, 'td[aria-label="Name"]'
          element :email, 'td[aria-label="Email"]'
          element :actions, 'td[aria-label="Actions"] a'
        end

        element :new_information_officer_button, 'a#action--new-responder-user'
        element :deactivate_team_link, 'a#action--deactivate-team'

        def row_for_directorate(name)
          directorates_list.find { |row|
             row.name.text == "View the details of #{name}"
          }
        end

        def row_for_business_unit(name)
          business_units_list.find { |row| row.name.text == name }
        end

        def row_for_information_officer(name_or_email)
          information_officers_list.find do |row|
            row.name.text == name_or_email ||
              row.email.text == name_or_email
          end
        end
      end
    end
  end
end
