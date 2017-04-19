module PageObjects
  module Pages
    module Cases
      class RespondPage < SitePrism::Page
        set_url '/cases/{id}/respond'

        element :reminders,    '.reminders'
        element :alert,        '.notice'
        element :mark_as_sent_button, 'a:contains("Mark response as sent")'
        element :back_link,  'a.button-secondary'
      end
    end
  end
end
