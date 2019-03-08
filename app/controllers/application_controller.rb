class ApplicationController < ActionController::Base

  include Pundit

  GLOBAL_NAV_EXCLUSION_PATHS    = %w{ /cases/filter }
  CSV_REQUEST_REGEX             = /\.csv$/

  before_action do
    unless self.class.to_s =~ /^Devise::/
      RavenContextProvider.set_context(self)
    end
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_paper_trail_whodunnit
  before_action :authenticate_user!, :set_user, except: [:ping, :healthcheck]
  before_action :set_global_nav, if: -> { current_user.present?  && global_nav_required? }
  before_action :add_security_headers

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def set_user
    @user = current_user
  end

  def current_user
    super
  end

  private

  def download_csv_request?
    uri = URI(request.fullpath)
    CSV_REQUEST_REGEX.match?(uri.path)
  end

  def add_security_headers
    headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    headers['Pragma'] = 'no-cache'
    headers['Expires'] = '-1'
    if Rails.env.production?
      headers['Strict-Transport-Security'] = 'max-age=31536000, includeSubDomains'
    end
  end

  # Don't bother setting the global nav for requests with paths in GLOBAL_NAV_EXCLUSION_PATHS
  def global_nav_required?
    GLOBAL_NAV_EXCLUSION_PATHS.exclude?(request.path)
  end

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

  def send_csv_cases(action_string)
    headers["Content-Type"] = 'text/csv; charset=utf-8'
    headers["Content-Disposition"] =
      %(attachment; filename="#{CSVGenerator.filename(action_string)}")
    self.response_body = CSVGenerator.new(@cases)
  end
end
