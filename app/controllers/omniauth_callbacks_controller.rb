class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found

  def azure_activedirectory_v2
    user = User.active_users.find_by!("email ILIKE ?", auth_info["email"])

    sign_in_and_redirect(
      user, event: :authentication
    )
  end

private

  def auth_info
    request.env["omniauth.auth"]["info"]
  end

  def user_not_found
    set_flash_message(:alert, :not_found, scope: translation_scope)
    redirect_to after_omniauth_failure_path_for(:user)
  end
end
