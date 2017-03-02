module PageObjects
  module Pages
    module Cases
      class RespondPage < SitePrism::Page
        set_url '/cases/{id}/respond'

        element :reminders,    '.reminders'
        element :alert,        '.alert-orange'
        element :mark_as_sent_button, 'a:contains("Mark response as sent")'
      end
    end
  end
end
