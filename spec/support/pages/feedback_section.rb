class ServiceFeedback < SitePrism::Section
  element :feedback_form, '#new_feedback'
  element :send_button, 'input[type="submit"].button-secondary'

  def send_feedback(msg)
    feedback_form.set msg
    send_button.click
  end
end
