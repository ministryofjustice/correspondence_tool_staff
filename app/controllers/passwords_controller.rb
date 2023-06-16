class PasswordsController < Devise::PasswordsController
  def create
    if resource_params[:email].blank?
      super
    else
      user = User.find_by(email: resource_params[:email].downcase)
      if user.nil?
        redirect_to new_user_session_path
      else
        super
      end
      flash[:notice] = I18n.t("devise.passwords.send_paranoid_instructions")
    end
  end

protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    new_user_session_path
  end
end
