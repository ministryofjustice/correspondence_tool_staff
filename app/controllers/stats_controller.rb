class StatsController < ApplicationController

  before_action :authorize_user

  def index
    @report_manager = Stats::ReportManager.new
  end

  def download
    @report_manager = Stats::ReportManager.new
    filename  = @report_manager.filename(params[:report_id])
    report = @report_manager.report_object(params[:report_id])
    report.run

    send_data report.to_csv, filename: filename
    flash[:notice] = "CSV file has been downloaded with name #{filename}"
  end

  private

  def authorize_user
    authorize Case.first, :can_download_stats?
  end
end

