module PageObjects
  module Sections
    module Shared
      class DropzoneJSPreviewTemplateSection < SitePrism::Section
        element :filename, ".dz-filename span[data-dz-name]"
        element :filesize, ".dz-filename span[data-dz-size]"
        element :progressbar, ".dz-progress span.dz-upload[data-dz-uploadprogress]"
        element :remove_link, ".dz-remove-link span[data-dz-remove]"
        element :error_message_container, ".dz-error-message span[data-dz-errormessage]"
      end
    end
  end
end
