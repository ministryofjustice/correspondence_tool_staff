class ContactDecorator < Draper::Decorator
  delegate_all

  def has_emails?
    data_request_emails.present? ? 'Yes' : 'No'
  end
end
