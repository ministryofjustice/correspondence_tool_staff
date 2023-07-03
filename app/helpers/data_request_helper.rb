module DataRequestHelper
  def only_branston_registry_email
    @recipient_emails.empty? || (@recipient_emails.count == 1 && @recipient_emails.include?("BranstonRegistryRequests2@justice.gov.uk"))

  end
end
