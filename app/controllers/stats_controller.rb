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

  def custom
    @report = Report.new
    @custom_reports = ReportType.custom.all
  end

  def create_custom

    stats_selector = Report.new(create_custom_params)

    if stats_selector.valid?
      report_type = ReportType.find(create_custom_params[:report_type_id])
      report = "Stats::#{report_type.class_name}".constantize.new(stats_selector.period_start,
                                                                  stats_selector.period_end)
      report.run

      stats_selector.report_data = report.to_csv
      stats_selector.save

      # send_data report.to_csv, {filename: filename, disposition: :attachment}
      flash[:download] =  "Report generated and #{view_context.link_to 'ready to download', stats_download_custom_path(id: stats_selector.id)}"
      redirect_to stats_custom_path
    else
      @report = Report.new(create_custom_params)

      #Set the validation error messages
      @report.save
      @custom_reports = ReportType.custom.all
      render :custom
    end
  end

  def download_custom
    report= Report.find(params[:id])
    filename = "#{ report.report_type.class_name.underscore}.csv"

    send_data report.report_data, {filename: filename, disposition: :attachment}
  end

  private

  def authorize_user
    authorize Case.first, :can_download_stats?
  end

  def set_reports
    @reports = ReportType.all.order(:seq_id)
  end

  def create_custom_params
    params.require(:report).permit(
      :report_type_id,
      :period_start_dd, :period_start_mm, :period_start_yyyy,
      :period_end_dd, :period_end_mm, :period_end_yyyy,
      )
  end
end

