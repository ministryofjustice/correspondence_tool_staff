class ApplicationController < ActionController::Base
  include Pundit::Authorization

  class ContentGoneError < StandardError; end

  GLOBAL_NAV_EXCLUSION_PATHS    = %w[/cases/filter].freeze
  CSV_REQUEST_REGEX             = /\.csv$/

  before_action do
    unless self.class.to_s =~ /^Devise::/
      SentryContextProvider.set_context(self)
    end
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :check_maintenance_mode

  before_action :set_paper_trail_whodunnit
  before_action :authenticate_user!, :set_user, except: %i[ping healthcheck maintenance_mode accessibility]
  before_action :set_global_nav, if: -> { current_user.present? && global_nav_required? }
  before_action :add_security_headers
  before_action :set_hompepage_nav, if: -> { current_user.present? && global_nav_required? }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from ContentGoneError do
    render file: Rails.root.join("public/410.html"), status: :gone, layout: false
  end

  def set_user
    @user = current_user
  end

  def maintenance_mode
    redirect_to "/" and return unless maintenance_mode_on?

    render "layouts/maintenance", layout: nil
  end

private

  def check_maintenance_mode
    if maintenance_mode_on? && request.fullpath != "/maintenance"
      redirect_to "/maintenance" and return
    end
  end

  def maintenance_mode_on?
    ENV["MAINTENANCE_MODE"] == "ON"
  end

  def download_csv_request?
    uri = URI(request.fullpath)
    CSV_REQUEST_REGEX.match?(uri.path)
  end

  def add_security_headers
    headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    headers["Pragma"] = "no-cache"
    headers["Expires"] = "-1"
    if Rails.env.production?
      headers["Strict-Transport-Security"] = "max-age=31536000, includeSubDomains"
    end
  end

  # Don't bother setting the global nav for requests with paths in GLOBAL_NAV_EXCLUSION_PATHS
  def global_nav_required?
    GLOBAL_NAV_EXCLUSION_PATHS.exclude?(request.path)
  end

  def user_not_authorized(exception, redirect_path = nil)
    policy_name = exception.policy.class.to_s.underscore

    flash[:alert] = t "pundit.#{policy_name}.#{exception.query}"
    redirect_to(redirect_path || request.referer || root_path)
  end

  def set_global_nav
    @global_nav_manager = GlobalNavManager.new(
      current_user,
      request,
      Settings.global_navigation.pages,
    )
  end

  def set_hompepage_nav
    @homepage_nav_manager = GlobalNavManager.new(
      current_user,
      request,
      Settings.homepage_navigation.pages,
    )
  end

  def send_csv_cases(action_string)
    specific_report = params[:report]
    if specific_report
      send_csv_case_by_specific_report(specific_report)
    else
      send_csv_case_by_default(action_string)
    end
  end

  def send_csv_case_by_specific_report(specific_report)
    headers["Content-Type"] = "text/csv; charset=utf-8"
    report_type = ReportType.find_by(abbr: specific_report)
    report_service_class = report_type.class_name.constantize
    report_service = report_service_class.new(case_scope: @cases)
    headers["Content-Disposition"] =
      %(attachment; filename="#{report_service.filename}")
    self.response_body = report_service.to_csv
  end

  def send_csv_case_by_default(action_string)
    headers["Content-Type"] = "text/csv; charset=utf-8"
    headers["Content-Disposition"] =
      %(attachment; filename="#{CSVGenerator.filename(action_string)}")
    self.response_body = CSVGenerator.new(@cases, CSVExporter.new(nil))
  end
end
