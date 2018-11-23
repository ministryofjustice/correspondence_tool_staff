module PageObjects
  module Sections
    module Shared
      class DropzoneFormSection < SitePrism::Section
        element :container, '.dropzone'
      end
    end
  end
end
