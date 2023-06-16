module PageObjects
  module Sections
    module Assignments
      class AssignToBusinessUnitSection < SitePrism::Section
        sections :team, "li.team" do
          element :business_unit, ".team-unit-name"
          element :assign_link, ".team-actions a"
          elements :areas_covered, ".areas-covered li"
          element :deputy_director, ".deputy-director"
        end
      end
    end
  end
end
