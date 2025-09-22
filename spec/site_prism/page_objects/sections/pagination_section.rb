module PageObjects
  module Sections
    class PaginationSection < SitePrism::Section
      element :prev_page_link, ".govuk-pagination__prev a"
      element :next_page_link, ".govuk-pagination__next a"
      element :page_number_links, ".govuk-pagination__list"
    end
  end
end
