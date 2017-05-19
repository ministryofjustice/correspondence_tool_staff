module PageObjects
  module Sections
    class CaseAttachmentSection < SitePrism::Section
      element :filename, '[aria-label="File name"]'

      section :actions, '.response-actions' do
        element :view, '.view'
        element :download, '.download'
        element :remove,   '.delete'
      end
    end
  end
end
