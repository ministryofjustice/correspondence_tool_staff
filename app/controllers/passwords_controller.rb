class PasswordsController < Devise::PasswordsController

  include ApplicationHelper

  def create
    super
    DeviseMailer.user_does_not_exist(@user.email).deliver_later
  end

  def new
    super
  end

  def update
    super
  end

  def edit
    super
  end

  protected
  def after_sending_reset_password_instructions_path_for(resource_name)
    new_user_session_path
  end
end
