module PageObjects
  module Pages
    class PasswordPage < SitePrism::Page
      set_url "/users/password/new"
      element :email_field, "#user_email"
      element :send, 'input[type="submit"][value="Send me password reset instructions"]'
      element :error_message, ".error-summary"
      section :service_feedback, PageObjects::Sections::ServiceFeedbackSection, ".feedback"
      section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

      def send_reset_instructions(email)
        email_field.set(email)
        send.click
      end
    end
  end
end
