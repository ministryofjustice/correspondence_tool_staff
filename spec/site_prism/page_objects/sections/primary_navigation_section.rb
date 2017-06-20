module PageObjects
  module Sections
    class PrimaryNavigationSection < SitePrism::Section
      elements :all_links, 'a'
      element :active_link, 'a.active'
      element :new_cases, 'a[href="/cases/incoming"]'
    end
  end
end
