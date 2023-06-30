module PageObjects
  module Sections
    module Cases
      class CaseMessagesSection < SitePrism::Section
        elements :all_user_messages,
                 ".message-list .message-right, .message-list .message-right"
      end
    end
  end
end
