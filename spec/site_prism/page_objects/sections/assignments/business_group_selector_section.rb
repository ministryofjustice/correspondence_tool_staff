module PageObjects
  module Sections
    module Assignments
      class BusinessGroupSelectorSection < SitePrism::Section
        elements :links, "li a"
        elements :group, "li.business-group"
        element :all_groups, "li.show-all"
      end
    end
  end
end
