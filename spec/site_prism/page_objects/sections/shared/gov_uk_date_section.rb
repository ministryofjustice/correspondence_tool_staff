module PageObjects
  module Sections
    module Shared
      class GovUKDateSection < SitePrism::Section
        element :day, :xpath, ".//input[contains(@name,'_dd')]", visible: false
        element :month, :xpath, ".//input[contains(@name,'_mm')]", visible: false
        element :year, :xpath, ".//input[contains(@name,'_yyyy')]", visible: false
      end
    end
  end
end
