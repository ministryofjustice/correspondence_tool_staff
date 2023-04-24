class CommissioningDocumentUploaderService
  attr_reader :kase, :current_user, :commissioning_document

  def initialize(kase:, current_user:, commissioning_document:)
    @kase = kase
    @current_user = current_user
    @commissioning_document = commissioning_document
  end

  def email
    email_sent
  end

  private

  def email_sent
    commissioning_document.sent = true
    commissioning_document.save
  end
end
