module PageObjects
  module Sections
    class UserCardSection < SitePrism::Section
      element :greetings, ".user-card--greetings"
      element :signout, ".user-card--signout"
    end
  end
end
