module PageObjects
  module Sections
    module Cases
      class ClearanceCopySection < SitePrism::Section
        element :action, "p:first-child"
        section :expectations, "p:last-child" do
          element :team, "strong:first-child"
          element :status, "strong:last-child"
        end
      end
    end
  end
end
