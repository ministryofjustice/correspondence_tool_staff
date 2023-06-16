module PageObjects
  module Pages
    module Teams
      class BusinessAreasCoveredPage < SitePrism::Page
        set_url "/teams/{id}/business_areas_covered"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :add_area_field, "#team_property_value"
        element :add_button, '.button-secondary[value="Add area"]'

        sections :existing_areas, "#js-areas-covered--all .grid-row" do
          element :value, ".business-areas--details"
          element :remove, '[data-method="delete"]'
          element :edit, ".edit-action"
          element :text_field, "input.form-control"
          element :save, 'input[type="submit"]'
        end

        element :create, ".button"

        def descriptions
          existing_areas.map do |row|
            row.value.text
          end
        end
      end
    end
  end
end
