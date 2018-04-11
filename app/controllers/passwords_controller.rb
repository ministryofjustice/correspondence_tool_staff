class PasswordsController < Devise::PasswordsController

  def create
    if !resource_params[:email].present?
      super
    else
      user = User.find_by(email: resource_params[:email])
      if user == nil
        redirect_to new_user_session_path
        flash[:notice] = I18n.t('devise.passwords.send_paranoid_instructions')
      elsif user.deactivated?
        ActionNotificationsMailer.account_not_active(user).deliver_later
        redirect_to new_user_session_path
        flash[:notice] = I18n.t('devise.passwords.send_paranoid_instructions')
      else
        super
        flash[:notice] = I18n.t('devise.passwords.send_paranoid_instructions')
      end
    end
  end

  protected
  def after_sending_reset_password_instructions_path_for(_resource_name)
    new_user_session_path
  end
end
