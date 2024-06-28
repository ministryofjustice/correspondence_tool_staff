module PageObjects
  module Sections
    class ServiceFeedbackSection < SitePrism::Section
      element :details_button, "summary"

      element :feedback_form, "#new_feedback"
      element :feedback_textarea, "#new_feedback textarea"

      element :send_button, ".button-secondary"
      element :success_notice, ".feedback-notification .alert-green"
      element :error_notice, ".feedback-notification .alert-red"

      def send_feedback(msg)
        feedback_form.set msg
        send_button.click
      end
    end
  end
end
