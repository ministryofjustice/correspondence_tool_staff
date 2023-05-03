class CommissioningDocumentEmailService
  attr_reader :data_request, :current_user, :commissioning_document

  def initialize(data_request:, current_user:, commissioning_document:)
    @data_request = data_request.decorate
    @current_user = current_user
    @commissioning_document = commissioning_document.decorate
  end

  def send!
    upload_document
    send_email
    email_sent
  end

  private

  def upload_document
    return if commissioning_document.attachment.present?

    file = Tempfile.new
    file.write(commissioning_document.document.force_encoding('UTF-8'))
    uploader = S3Uploader.new(data_request.kase, current_user)
    attachment = uploader.upload_file_to_case(:commissioning_document, file, commissioning_document.filename)
    commissioning_document.update_attribute(:attachment, attachment)
  end

  def send_email
    data_request.contact.all_emails.map do |email|
      ActionNotificationsMailer.commissioning_email(
        commissioning_document,
        email,
      ).deliver_later
    end
  end

  def email_sent
    commissioning_document.update_attribute(:sent, true)
    data_request.kase.state_machine.send_day_1_email!(
      acting_user: current_user,
      acting_team: BusinessUnit.dacu_branston,
      message: "#{commissioning_document.request_document} requested from #{data_request.location}",
    )
  end
end
