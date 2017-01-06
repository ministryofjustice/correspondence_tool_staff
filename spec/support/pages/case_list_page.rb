class CaseList < SitePrism::Section
  element :name, 'td[aria-label="Requester name"]'
  element :subject, 'td[aria-label="Subject"]'
  element :external_deadline, 'td[aria-label="External deadline"]'
  element :status, 'td[aria-label="Status"]'
end

class CaseListPage < SitePrism::Page
  set_url '/'

  sections :case_list, ::CaseList, '.case_row'
end
