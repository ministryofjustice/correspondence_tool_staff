class CaseList < SitePrism::Section
  element :name, '.name'
  element :subject, '.subject'
  element :message, '.message'
  element :category, '.category'
  element :received, '.received'
  element :internal_deadline, '.internal_deadline'
  element :external_deadline, '.external_deadline'
end

class CaseListPage < SitePrism::Page
  set_url '/'

  sections :case_list, ::CaseList, '.case_row'
end
