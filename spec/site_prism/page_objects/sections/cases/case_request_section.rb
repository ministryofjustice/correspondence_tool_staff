module PageObjects
  module Sections
    module Cases
      class CaseRequestSection < SitePrism::Section
        element :message, 'p'
        element :show_more_link, '.ellipsis-button'
        element :ellipsis, '.ellipsis-delimiter'
        element :collapsed_text, '.ellipsis-complete'
        element :preview, '.ellipsis-preview'

        sections :attachments,
                 PageObjects::Sections::Cases::CaseAttachmentSection,
                 '.case-attachments-group'
      end
    end
  end
end
