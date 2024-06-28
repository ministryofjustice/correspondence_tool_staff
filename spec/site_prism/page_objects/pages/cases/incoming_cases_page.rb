module PageObjects
  module Pages
    module Cases
      class IncomingCasesPage < SitePrism::Page
        set_url "/cases/incoming"

        section :user_card, PageObjects::Sections::UserCardSection, ".user-card"
        sections :case_list, ".case_row" do
          elements :highlight_row, "td.ajax-success, td.ajax-success--de-escalate"

          element :number, 'td[aria-label="Case number"]'
          element :number_link, 'td[aria-label="Case number"] a'
          section :request, 'td[aria-label="Request"]' do
            element :name, ".case_name"
            element :subject, ".case_subject"
            element :message, ".case_message_extract"
          end
          section :actions, 'td[aria-label="Actions"]' do
            element :take_on_case, ".take-case-on-link"
            element :success_message, ".action-success"
            element :undo_assign_link, ".action-success a"
            element :de_escalate_link, ".de-escalate-link"
            element :undo_de_escalate_link, ".js-undo-de-escalate-link"
            element :requested_by, ".container-notices"
          end
        end

        section :service_feedback, PageObjects::Sections::ServiceFeedbackSection, "#feedback"
        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"
        section :homepage_navigation, PageObjects::Sections::HomepageNavigationSection, "#homepage-navigation"

        def case_numbers
          case_list.map do |row|
            row.number.text.delete("Case number").delete("\n")
          end
        end

        def row_for_case_number(number)
          case_list.find do |row|
            row.number.text.delete("Case number").delete("\n") == number
          end
        end
      end
    end
  end
end
