class CorrespondenceDetailsPage < SitePrism::Page
  set_url '/correspondence/{id}'

  element :correspondent_name, '#correspondent_name'
  element :correspondent_email, '#correspondent_email'
  element :message, '#message'
  element :category, '#category'
  element :escalation_deadline, '#escalation_deadline'
  element :internal_deadline, '#internal_deadline'
  element :external_deadline, '#external_deadline'
  element :status, '#status'
end
