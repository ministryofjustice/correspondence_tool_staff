module PageObjects
  module Sections
    module Cases
      class CaseAttachmentSection < SitePrism::Section
        element :section_heading, "h2.request--heading"

        sections :collection, ".case-attachments-report tbody tr" do
          element :filename, 'td[aria-label="File name"]'

          section :actions, 'td[aria-label="Actions"]' do
            element :view, ".view"
            element :download, ".download"
            element :remove,   ".delete"
          end
        end
      end
    end
  end
end
