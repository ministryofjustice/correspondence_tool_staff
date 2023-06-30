module PageObjects
  module Sections
    module Cases
      class WhatDoYouWantToDoSection < SitePrism::Section
        element :take_case_on_link, ".take-case-on-link"
        element :de_escalate_link, ".de-escalate-link"
      end
    end
  end
end
