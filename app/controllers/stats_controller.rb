class StatsController < ApplicationController

  before_action :authorize_user

  def index
    @foi_reports = ReportType.standard.foi.order(:full_name)
    @sar_reports = ReportType.standard.sar.order(:full_name)
  end

  def download
    report = Report.new report_type_id: params[:id]
    report.run

    send_data report.report_data, filename: report.report_type.filename
  end

  def download_audit
    report = Stats::R900AuditReport.new
    report.run
    send_data report.report_data, filename: "R900Audit.csv"
  end

  def custom
    @report = Report.new
    @custom_reports_foi = ReportType.custom.foi
    @custom_reports_sar = ReportType.custom.sar
    @correspondence_types = CorrespondenceType.by_report_category
    if FeatureSet.sars.disabled?
      @report.correspondence_type = 'FOI'
    end
  end

  def create_custom_report
    @report = Report.new(create_custom_params)

    if @report.valid?
      @report.run(@report.period_start, @report.period_end)

      flash[:download] =  "Your custom report has been created. #{view_context.link_to 'Download', stats_download_custom_report_path(id: @report.id)}"
      redirect_to stats_custom_path
    else
      if create_custom_params[:correspondence_type].blank?
        @report.errors.add(:correspondence_type, :blank)
        @report.errors.delete(:report_type_id)
      end
      @correspondence_types = CorrespondenceType.all
      @custom_reports_foi = ReportType.custom.foi
      @custom_reports_sar = ReportType.custom.sar
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
    authorize Case::Base, :can_download_stats?
  end

  def create_custom_params
    params.require(:report).permit(
      :correspondence_type,
      :report_type_id,
      :period_start_dd, :period_start_mm, :period_start_yyyy,
      :period_end_dd, :period_end_mm, :period_end_yyyy,
      )
  end
end
