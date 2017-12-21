class StatsController < ApplicationController

  before_action :authorize_user

  before_action :set_reports,
                only: :index

  def index
  end

  def download
    report_type = ReportType.find(params[:id])

    report = Report.where(report_type_id: report_type.id).last
    unless report.present?
      report = Report.create report_type_id: report_type.id
      report.run
    end

    send_data report.report_data, filename: report_type.filename
  end

  def custom
    @report = Report.new
    @custom_reports = ReportType.custom.all
  end

  def create_custom_report

    @report = Report.new(create_custom_params)

    if @report.valid?
      @report.run(@report.period_start, @report.period_end)

      flash[:download] =  "Your custom report has been created. #{view_context.link_to 'Download', stats_download_custom_report_path(id: @report.id)}"
      redirect_to stats_custom_path
    else
      @custom_reports = ReportType.custom.all
      render :custom
    end
  end

  def download_custom_report
    report= Report.find(params[:id])
    filename = report.report_type.filename

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

