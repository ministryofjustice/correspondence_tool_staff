class DataRequestEmailDecorator < Draper::Decorator
  delegate_all

  def created_at
    I18n.l(super, format: :default)
  end

  def email_type
    I18n.t("helpers.label.data_request_email.email_type.#{super}", chase_number:)
  end

  def status
    super.humanize
  end
end
