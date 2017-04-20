module PageObjects
  module Sections
    class PrimaryNavigationSection < SitePrism::Section
      elements :all_links, 'a'
      element :active_link, 'a.active'
    end
  end
end
