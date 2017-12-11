module PageObjects
  module Sections
    class PrimaryNavigationSection < SitePrism::Section
      elements :all_links, 'a'
      element :active_link, 'a.active'
      element :new_cases, 'a[href="/cases/incoming"]'
      element :search, 'a[href="/cases/search"]'
      element :settings, 'a[href="/teams"]'
      element :stats, 'a[href="/stats"]'
    end
  end
end
