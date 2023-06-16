module PageObjects
  module Pages
    module Teams
      class IndexPage < SitePrism::Page
        set_url "/teams"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        element :heading, "h1.page-heading"

        sections :business_groups_list, ".report tbody tr" do
          element :name, 'td[aria-label="Name"] a'
          element :director_general, 'td[aria-label="Director general"]'
          element :num_directorates, 'td[aria-label="Directorates"]'
        end

        def row_for_business_group(name)
          Capybara.ignore_hidden_elements = false
          business_groups_list.find do |row|
            row.name.text == "View the details of #{name}"
          end
        ensure
          Capybara.ignore_hidden_elements = true
        end
      end
    end
  end
end
