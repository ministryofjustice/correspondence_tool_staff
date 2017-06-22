module PageObjects
  module Sections
    module Cases
      class CaseAttachmentSection < SitePrism::Section

        sections :collection, '.case-attachments-report tbody tr' do

          element :filename, 'td[aria-label="File name"]'

          section :actions, 'td[aria-label="Actions"]' do
            element :view, '.view'
            element :download, '.download'
            element :remove,   '.delete'
          end
        end

      end
    end
  end
end
