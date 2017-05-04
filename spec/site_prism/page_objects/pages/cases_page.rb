module PageObjects
  module Pages
    class CasesPage < SitePrism::Page
      set_url '/'

      section :user_card, PageObjects::Sections::UserCardSection, '.user-card'
      sections :case_list, '.case_row' do
        element :number, 'td[aria-label="Case number"]'
        element :name, 'td[aria-label="Requester name"]'
        element :subject, 'td[aria-label="Subject"]'
        element :external_deadline, 'td[aria-label="Final deadline"]'
        element :status, 'td[aria-label="Waiting for"]'
        element :who_its_with, 'td[aria-label="With"]'
      end

      element :new_case_button, 'a.button[href="/cases/new"]'
      section :service_feedback, PageObjects::Sections::ServiceFeedbackSection, '.feedback'
      section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

      def case_numbers
        case_list.map do |row|
          row.number.text.delete('Link to case')
        end
      end
    end
  end
end
