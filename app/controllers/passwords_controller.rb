class PasswordsController < Devise::PasswordsController

  def create
    ap resource_params
    user = User.find_by(email: resource_params[:email])
    if user.deactivated?
      DeviseMailer
        .account_not_active(user)
        .deliver_later
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      super
    end
  end

  protected
  def after_sending_reset_password_instructions_path_for(_resource_name)
    new_user_session_path
  end
end
