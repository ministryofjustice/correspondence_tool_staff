module PageObjects
  module Sections
    module Shared
      class GovUKDateSection < SitePrism::Section
        # NB: The fields here are set as 'visible: false' to allow them to be
        #     used for hidden date fields (like the received_date on ICO
        #     Overturned cases). However, if they field really is not visible
        #     then while you can test for it's presence using these, you can't
        #     set the value of the fields.
        element :day, :xpath, ".//input[contains(@name,'_dd')]", visible: false
        element :month, :xpath, ".//input[contains(@name,'_mm')]", visible: false
        element :year, :xpath, ".//input[contains(@name,'_yyyy')]", visible: false
      end
    end
  end
end
