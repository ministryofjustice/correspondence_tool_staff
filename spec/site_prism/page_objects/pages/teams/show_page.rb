module PageObjects
  module Pages
    module Teams
      class ShowPage < SitePrism::Page
        set_url '/teams/{id}'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'


        element :heading, 'h1.page-heading'

        sections :directorates_list, '.report tbody tr' do
          element :name, 'td[aria-label="Name"] a'
          element :director, 'td[aria-label="Director"]'
          element :num_business_units, 'td[aria-label="Directorates"]'
          element :action, 'td[aria-label="Actions"]'
        end

        sections :business_units_list, '.report tbody tr' do
          element :name, 'td[aria-label="Name"] a'
          element :deputy_director, 'td[aria-label="Deputy Director"]'
          element :num_children, 'td[aria-label="Information Officers"]'
          element :actions, 'td[aria-label="Actions"]'
        end

        sections :information_officers_list, '.report tbody tr' do
          element :name, 'td[aria-label="Name"]'
          element :email, 'td[aria-label="Email"]'
          element :actions, 'td[aria-label="Actions"]'
        end

        def row_for_directorate(name)
          directorates_list.find { |row|
             row.name.text == "View the details of #{name}"
          }
        end

        def row_for_business_unit(name)
          business_units_list.find { |row| row.name.text == name }
        end

        def row_for_information_officer(name, email)
          information_officers_list.find { |row|
            row.name.text == name && row.email.text == email
          }
        end
      end
    end
  end
end

