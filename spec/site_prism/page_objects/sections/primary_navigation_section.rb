module PageObjects
  module Sections
    class PrimaryNavigationSection < SitePrism::Section
      elements :all_links, "a"
      element :active_link, "a.active"
      element :all_open_cases, 'a[href="/cases/open"]'
      element :search, 'a[href="/cases/search"]'
      element :settings, 'a[href="/teams"]'
      element :stats, 'a[href="/stats"]'
      element :my_open_in_time, 'a[href="/cases/my_open/in_time"]'
    end
  end
end
