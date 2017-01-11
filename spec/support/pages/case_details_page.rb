class CaseDetailsPage < SitePrism::Page
  set_url '/cases/{id}'

  element :correspondent_name, '#correspondent_name'
  element :correspondent_email, '#correspondent_email'
  element :message, '#message'
  element :category, '#category'
  element :escalation_deadline, '#escalation_deadline'
  element :external_deadline, '#external_deadline'
  element :status, '#status'
  element :escalation_notice, '.alert-orange'
end
