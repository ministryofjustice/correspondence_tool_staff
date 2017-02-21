class CaseDetailsPage < SitePrism::Page
  set_url '/cases/{id}'
  # TODO: the sections here ... actually this whole page, can show up in other
  #       locations (cases/assignments/edit, cases/assignments/show_rejected)
  #       so we should be moving most/all of this into separate section files
  #       for inclusion into those pages.

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
    sections :files, 'tr.case_attachment_row' do
      element :filename, 'td[aria-label="File name"]'
      elements :actions, 'td[aria-label="Actions"] a'
      # XPath allows us to use contains(), while the CSS selector :contains()
      # breaks in tests with JS enabled (PhantomJS not supporting CSS3??)
      element :download, :xpath, '//td[@aria-label="Actions"]//a[contains(.,"Download")]'
      element :remove,   :xpath, '//td[@aria-label="Actions"]//a[contains(.,"Remove")]'
    end
  end
end
