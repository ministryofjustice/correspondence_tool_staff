module SitePrism
  module Support
    module AssignToBusinessUnitHelpers
      def choose_business_unit(team)
        business_unit = assign_to.find("h3 div", text: team.name)
        container = business_unit.find(:xpath, "../../..")
        container.find("a.button").click
      end

      def choose_business_group(group)
        business_groups.find_link(group.name).click
      end
    end
  end
end
