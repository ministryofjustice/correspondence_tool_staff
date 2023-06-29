require "page_objects/sections/cases/case_attachment_section"

module PageObjects
  module Sections
    module Cases
      class CaseRequestSection < SitePrism::Section
        element :message, "p.message-body"
        element :show_more_link, ".ellipsis-button"
        element :ellipsis, ".ellipsis-delimiter"
        element :hidden_ellipsis, ".js-hidden"
        element :collapsed_text, ".ellipsis-complete"
        element :hidden_collapsed_text, ".ellipsis-complete.js-hidden"
        element :preview, ".ellipsis-preview"

        sections :attachments,
                 PageObjects::Sections::Cases::CaseAttachmentSection,
                 ".case-attachments-group"
      end
    end
  end
end
