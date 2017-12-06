class StatsController < ApplicationController

  before_action :authorize_user

  before_action :set_reports,
                only: :index

  def index
  end

  def download
    report_type = ReportType.find(params[:id])

    filename  = "#{report_type[:class_name].underscore}.csv"

    report = "Stats::#{report_type.class_name}".constantize.new
    report.run

    send_data report.to_csv, filename: filename
  end
    report.run

    send_data report.to_csv, filename: filename
    flash[:notice] = "CSV file has been downloaded with name #{filename}"
  end

  private

  def authorize_user
    authorize Case.first, :can_download_stats?
  end

  def set_reports
    @reports = ReportType.all.order(:seq_id)
  end
end

