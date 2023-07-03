module DataRequestHelper
  def only_branston_registry_email
    recipient_emails = instance_variable_get(:@recipient_emails)
    recipient_emails.empty? || (recipient_emails.count == 1 && recipient_emails.include?(CommissioningDocumentTemplate::Probation::BRANSTON_ARCHIVES_EMAIL))
  end
end
