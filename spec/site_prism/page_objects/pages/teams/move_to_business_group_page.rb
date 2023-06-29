module PageObjects
  module Pages
    module Teams
      class MoveToBusinessGroupPage < SitePrism::Page
        set_url "/teams/{id}/move_to_business_group"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :heading, ".page-heading--primary"
        element :subhead, ".page-heading--secondary"

        section :business_group_list, "ul.teams" do
          sections :business_groups, "li.team" do
            element :business_group_details, "div.team-details"
            element :move_to_business_group_link, "div.team-actions a"
          end
        end

        def find_row(business_group_name)
          business_group_list.business_groups.find do |item|
            item.business_group_details.text == business_group_name
          end
        end
      end
    end
  end
end
