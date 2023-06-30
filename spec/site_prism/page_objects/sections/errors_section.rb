module PageObjects
  module Sections
    class Errors < SitePrism::Section
      element :heading, ".error-summary-heading"
      elements :details, ".error-summary-list li"
    end
  end
end
