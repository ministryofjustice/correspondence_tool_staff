module PageObjects
  module Sections
    class ResponseAttachmentSection < SitePrism::Section
      element :filename, '[aria-label="File name"]'
      element :view, :xpath, '*/a[contains(.,"View")]'
      element :download, :xpath, '*/a[contains(.,"Download")]'
      element :remove,   :xpath, '*/a[contains(.,"Remove")]'
    end
  end
end
