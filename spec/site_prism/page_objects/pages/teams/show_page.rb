module PageObjects
  module Pages
    module Teams
      class ShowPage < SitePrism::Page
        set_url '/teams/{id}'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'


        element :heading, 'h1.page-heading'
        element :deputy_director, 'h2:first'
        element :director, 'h2:first'
        element :director_general, 'h2:first'

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
          element :actions, 'td[aria-label="Actions"]'
        end

        element :new_information_officer_button, 'a#action--new-responder-user'

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

