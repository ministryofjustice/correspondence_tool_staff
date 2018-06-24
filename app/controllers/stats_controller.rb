class StatsController < ApplicationController

  before_action :authorize_user

  before_action :set_reports,
                only: :index

  def index
  end

  def download
    report_type = ReportType.find(params[:id])

    report = Report.where(report_type_id: report_type.id).last
    if !report.present? || !report_is_current?(report)
      report = Report.create report_type_id: report_type.id
      report.run
      report.trim_older_reports
    end

    send_data report.report_data, filename: report_type.filename
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
    @correspondence_types = CorrespondenceType.all
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

  def report_is_current?(report)
    job_config = get_job_config 'config/sidekiq-background-jobs.yml',
                                report.report_type.abbr
    scheduled_time = job_previous_run_time(job_config)
    report.created_at >= scheduled_time
  rescue
    false
  end

  def get_job_config(filename, report_type_abbr)
    sidekiq_config = YAML.load_file(
      Rails.root.join(filename)
    )
    if sidekiq_config.has_key?(Rails.env)
      sidekiq_config.merge! sidekiq_config[Rails.env]
    end
    sidekiq_config[:schedule].find do |_name, config|
      config['args'] == [report_type_abbr]
    end.last
  end

  def job_previous_run_time(job_config)
    if job_config.has_key?('cron')
      Rufus::Scheduler::CronLine
        .new(job_config['cron'])
        .previous_time.to_local_time
    elsif job_config.has_key?('every')
      Rufus::Scheduler
        .parse(job_config['every'].first)
        .seconds.ago
    end
  end
end
