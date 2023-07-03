module DataRequestHelper
  def only_branston_registry_email
    @recipient_emails.empty? || (@recipient_emails.count == 1 && @recipient_emails.include?(CommissioningDocumentTemplate::Probation::BRANSTON_ARCHIVES_EMAIL)) # rubocop:disable Rails::HelperInstanceVariable
  end
end
