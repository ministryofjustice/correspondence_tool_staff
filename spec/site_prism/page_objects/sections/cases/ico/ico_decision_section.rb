module PageObjects
  module Sections
    module Cases
      module ICO
        class ICODecisionSection < SitePrism::Section
          element :summary, ".request--message p:eq(1)"
          element :comments, ".request--message p:eq(2)"

          sections :attachments, ".case-attachments-report tbody tr" do
            element :file_name, 'td[aria-label="File name"]'
          end
        end
      end
    end
  end
end
