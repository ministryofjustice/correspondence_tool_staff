class ApplicationController < ActionController::Base

  include Pundit

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!, :set_user, except: [:ping, :healthcheck]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def set_user
    @user = current_user
  end

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:alert] = t "pundit.#{policy_name}.#{exception.query}"
    redirect_to(request.referrer || root_path)
  end

end
