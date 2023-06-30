module PageObjects
  module Sections
    class PaginationSection < SitePrism::Section
      element :prev_page_link, ".pagination-prev a"
      element :next_page_link, ".pagination-next a"
    end
  end
end
