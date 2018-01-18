class PasswordsController < Devise::PasswordsController
  protected
  def after_sending_reset_password_instructions_path_for(resource_name)
    new_user_session_path
  end

  # def new
  #   super
  # end

  # def create
  #   super
  # end
end
