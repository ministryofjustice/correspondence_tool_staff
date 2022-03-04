class DeviseMailer < Devise::Mailer

  # gives access to all helpers defined within `application_helper`.
  helper :application
  # Optional. eg. `confirmation_url`
  include Devise::Controllers::UrlHelpers

  def reset_password_instructions record, token, _opts={}
    SentryContextProvider.set_context
    set_template(Settings.reset_password_instructions_notify_template)

    set_personalisation(
        email_subject: 'Password reset',
        user_full_name: record.full_name,
        edit_password_url: edit_password_url(record, reset_password_token: token)
    )

    mail(to: record.email)
  end

  def unlock_instructions(record, token, _opts={})
    SentryContextProvider.set_context
    set_template(Settings.unlock_user_account_template)

    set_personalisation(
        email_subject: 'Your CMS user account has been locked',
        user_full_name: record.full_name,
        user_unlock_url: user_unlock_url(unlock_token: token)
    )

    mail(to: record.email)
  end

end
