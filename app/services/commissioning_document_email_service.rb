class CommissioningDocumentEmailService
  attr_reader :data_request_area, :current_user, :commissioning_document

  def initialize(data_request_area:, current_user:, commissioning_document:)
    @data_request_area = data_request_area.decorate
    @current_user = current_user
    @commissioning_document = commissioning_document.decorate
  end

  def send!
    send_emails
    email_sent
  end

private

  def send_emails
    emails = data_request_area.recipient_emails

    emails.map do |email|
      ActionNotificationsMailer.commissioning_email(
        commissioning_document,
        data_request_area.offender_sar_case.number,
        email,
      ).deliver_later! # must use deliver_later! method or Notify ID cannot be saved due to limitations of govuk_notify_rails gem
    end
  end

  def email_sent
    commissioning_document.update_attribute(:sent, true) # rubocop:disable Rails/SkipsModelValidations
    data_request_area.kase.state_machine.send_day_1_email!(
      acting_user: current_user,
      acting_team: BusinessUnit.dacu_branston,
      message: I18n.t("helpers.label.data_request_area.data_request_area_type.#{data_request_area.data_request_area_type}") + " requested from #{data_request_area.location}",
    )
  end
end
