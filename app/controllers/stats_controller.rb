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

  # RAG (Red, Amber, Green) thresholds for the different types
  # Columns E, K and Q are percentages (non-trigger, trigger and overall)
  # These are row items 4, 11 and 16.
  RAG_THRESHOLDS_FOI = {red: 85, amber: 90}
  RAG_THRESHOLDS_SAR = {red: 80, amber: 85}

  COLOURED_ROWS = {'E' => 4, 'K' => 11, 'Q' => 16}

  def cell_colour(value, thresholds)
    if value < thresholds[:red]
      'FF0000'
    elsif value < thresholds[:amber]
      'FF0000'
    else
      '00FF00'
    end
  end

  def download_custom_report #rubocop:disable Metrics/MethodLength
    report = Report.find(params[:id])
    filename = report.report_type.filename

    # This is a Spike - so just hack the report about to show that an Excel report is possible
    if report.report_type.abbr == 'R003'
      # split report data into pieces - convert "" into empty string
      excel_data = report.report_data.split("\n").map { |j| j.split(',') }
      # Hack alert - SAR/FOI have different thresholds. This isn't really a good way of telling them apart
      is_foi_report = excel_data[0][0].include?('FOI')
      thresholds = is_foi_report ? RAG_THRESHOLDS_FOI : RAG_THRESHOLDS_SAR
      axlsx = Axlsx::Package.new
      workbook = axlsx.workbook
      workbook.add_worksheet do |sheet|
        cell_colours = {}
        excel_data.each_with_index do |row, row_index|
          # The row data includes '""' for blank cells - so lose those.
          excel_row = row.map { |i| i == '""' ? '' : i }
          sheet.add_row excel_row
          # data rows start at index 3
          if row_index >= 3
            # Following the percentages values is the case count.
            # If that number is zero then we display a 0 percentage even though is technically
            # NaN (0/0) - so check so that we don't report that as a Red RAG rating
            COLOURED_ROWS.each do |cell, cell_index|
              if row[cell_index+1] != "0" #This is the case count - don't mark 0/0 as Red RAG rating...
                cell_colours["#{cell}#{row_index+1}"] = cell_colour(row[cell_index].to_f, thresholds)
              end
            end
          end
        end
        cell_colours.each do |cell, colour|
          sheet.add_style(cell, bg_color: colour)
        end
      end

      send_data axlsx.to_stream.read,
                filename: filename.gsub('.csv', '.xlsx'),
                disposition: :attachment,
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    else
      send_data report.report_data, {filename: filename, disposition: :attachment}
    end
  end

  private

  def authorize_user
    authorize Case::Base, :can_download_stats?
  end

  def set_reports
    @foi_reports = ReportType.standard.foi.order(:full_name)
    @sar_reports = ReportType.standard.sar.order(:full_name)
  end

  def create_custom_params
    params.require(:report).permit(
      :correspondence_type,
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
