class CaseResponsePage < SitePrism::Page
  set_url '/cases/{id}/respond'

  element :reminders,             '.reminders'
  element :alert,                 '.alert-orange'
end
