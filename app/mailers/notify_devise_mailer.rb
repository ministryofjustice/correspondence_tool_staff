class NotifyDeviseMailer < Devise::Mailer
  #rescue_from Exception, with: :log_errors

  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def reset_password_instructions record, token, opts={}

    set_template('705029c9-d7e4-47a6-a963-944cb6d6b09c')

    set_personalisation(
        email_subject: 'Password reset',
        user_full_name: record.full_name,
        edit_password_url: edit_password_url(record, reset_password_token: token)
    )

    mail(to: record.email)
  end

end
