class CaseDetailsPage < SitePrism::Page
  set_url '/cases/{id}'

  element :message, '.request'
  element :received_date, '.request--date-received'
  element :escalation_notice, '.alert-orange'

  section :sidebar, 'section.case-sidebar' do
    element :external_deadline, '.external_deadline .case-sidebar__data'
    element :status, '.status .case-sidebar__data'
    element :who_its_with, '.who-its-with .case-sidebar__data'
    element :name, '.name .case-sidebar__data'
    element :requester_type, '.case-sidebar__data--contact .requester-type'
    element :email, '.case-sidebar__data--contact .email'
    element :postal_address, '.case-sidebar__data--contact .postal-address'
    element :actions, '.actions .case-sidebar__data'
    element :mark_as_sent_button, 'a:contains("Mark response as sent")'
  end

  section :case_heading, '.case-heading' do
    element :case_number, '.case-heading--secondary'
  end

  section :uploaded_files, 'table#uploaded-files' do
    sections :files, 'tr' do
      element :filename, 'td[aria-label="File name"]'
      element :download, 'td[aria-label="Actions"] a:contains("Download")'
      element :remove,   'td[aria-label="Actions"] a:contains("Remove")'
,    end
  end
end
