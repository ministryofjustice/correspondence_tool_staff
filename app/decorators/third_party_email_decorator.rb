class ThirdPartEmailDecorator < Draper::Decorator
  delegate_all

  def created_at
    I18n.l(super, format: :default)
  end

  def email_type
    I18n.t("helpers.label.third_party_email.email_type.#{super}")
  end

  def status
    super.humanize
  end
end
