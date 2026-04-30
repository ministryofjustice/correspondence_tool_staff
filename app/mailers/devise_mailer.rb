class DeviseMailer < Devise::Mailer
  include PublishesSystemLogEmail

  # gives access to all helpers defined within `application_helper`.
  helper :application
  # Optional. eg. `confirmation_url`
  include Devise::Controllers::UrlHelpers

  after_deliver :publish_email_sent_event

  def reset_password_instructions(record, token, _opts = {})
    SentryContextProvider.set_context
    set_email_event_context(record, "reset_password_instructions")
    set_template(Settings.reset_password_instructions_notify_template)

    set_personalisation(
      email_subject: "Password reset",
      user_full_name: record.full_name,
      edit_password_url: edit_password_url(record, reset_password_token: token),
    )

    mail(to: record.email)
  end

  def unlock_instructions(record, token, _opts = {})
    SentryContextProvider.set_context
    set_email_event_context(record, "unlock_instructions")
    set_template(Settings.unlock_user_account_template)

    set_personalisation(
      email_subject: "Your CMS user account has been locked",
      user_full_name: record.full_name,
      user_unlock_url: user_unlock_url(unlock_token: token),
    )

    mail(to: record.email)
  end

private

  def email_event_context
    @email_event_context || {}
  end

  def set_email_event_context(record, email_type)
    @email_event_context = {
      category: "account_access",
      email_type:,
      recipient_type: "internal_staff",
      user_id: record.id,
    }
  end
end
