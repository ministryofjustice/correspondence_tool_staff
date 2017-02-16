require 'support/pages/feedback_section'

class UserCard < SitePrism::Section
  element :greetings, '.user-card--greetings'
  element :signout, '.user-card--signout'
end

class CaseList < SitePrism::Section
  element :number, 'td[aria-label="Case number"]'
  element :name, 'td[aria-label="Requester name"]'
  element :subject, 'td[aria-label="Subject"]'
  element :external_deadline, 'td[aria-label="External deadline"]'
  element :status, 'td[aria-label="Status"]'
  element :who_its_with, 'td[aria-label="Who it\'s with"]'
end

class CaseListPage < SitePrism::Page
  set_url '/'

  sections :case_list,::CaseList, '.case_row'
  section :user_card, UserCard, '.user-card'

  section :service_feedback, SitePrism::Section::ServiceFeedback, '.feedback'

  def case_numbers
    case_list.map do |row|
      row.number.text.delete('Link to case')
    end
  end

end
