class PasswordsController < Devise::PasswordsController

  def create
    if !resource_params[:email].present?
      super
    else
      user = User.find_by(email: resource_params[:email])
      if user == nil
        flash[:notice] = t('devise.passwords.send_paranoid_instructions')
        redirect_to new_user_session_path
      elsif user.deactivated?
        ActionNotificationsMailer
          .account_not_active(user)
          .deliver_later
        flash[:notice] = t('devise.passwords.send_paranoid_instructions')
        redirect_to new_user_session_path
      else
        super
      end
    end
  end

  protected
  def after_sending_reset_password_instructions_path_for(_resource_name)
    new_user_session_path
  end
end
