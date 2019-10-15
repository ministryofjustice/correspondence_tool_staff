module PageObjects
  module Sections
    class HomepageNavigationSection < SitePrism::Section
      elements :all_links, 'a'
      element :active_link, 'a.active'
      element :all_open_cases, 'a[href="/cases/open"]'
      element :new_cases, 'a[href="/cases/incoming"]'
    end
  end
end
