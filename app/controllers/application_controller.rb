class ApplicationController < ActionController::Base

  include Pundit

  before_action do
    RavenContextProvider.set_context(self)
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!, :set_user, except: [:ping, :healthcheck]
  before_action :set_global_nav, if: -> { current_user.present? }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def set_user
    @user = current_user
  end

  private

  def user_not_authorized(exception, redirect_path = nil)
    policy_name = exception.policy.class.to_s.underscore

    flash[:alert] = t "pundit.#{policy_name}.#{exception.query}"
    redirect_to(redirect_path || request.referrer || root_path)
  end

  def set_global_nav
    @global_nav_manager = GlobalNavManager.new(
      current_user,
      request,
      Settings.global_navigation,
    )
  end

  # def set_raven_context
  #   puts ">>>>>>>>>>>>>> SSETTING RAVEN CONTEXT #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
  #   Raven.user_context(id: current_user.id, email: current_user.email)
  #   Raven.extra_context(host: ENV['ENV'] || 'Not set', myname: 'Stephen Richards')
  # end
end
