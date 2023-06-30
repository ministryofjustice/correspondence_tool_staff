module PageObjects
  module Sections
    class PageHeadingSection < SitePrism::Section
      element :heading, ".page-heading--primary"
      element :sub_heading, ".page-heading--secondary"
    end
  end
end
