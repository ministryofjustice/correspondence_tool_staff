class StatsController < ApplicationController

  before_action :authorize_user

  def index
    @foi_reports = ReportType.standard.foi.order(:full_name)
    @sar_reports = ReportType.standard.sar.order(:full_name)
  end

  def download
    report = Report.new report_type_id: params[:id]
    report.run_and_update!
    report.trim_older_reports

    send_data report.report_data, filename: report.report_type.filename('csv')
  end

  def download_audit
    report = Stats::R900AuditReport.new
    report.run_and_update!
    send_data report.report_data, filename: "R900Audit.csv"
  end

  def custom
    @report = Report.new
    set_fields_for_custom_action
    if FeatureSet.sars.disabled?
      @report.correspondence_type = 'FOI'
    end
  end

  def create_custom_report
    @report = Report.new(create_custom_params)

    if @report.valid?
      if @report.xlsx?
        report_data = @report.run(@report.period_start, @report.period_end)

        axlsx = create_spreadsheet(report_data)

        send_data axlsx.to_stream.read,
                  filename: @report.report_type.filename('xlsx'),
                  disposition: :attachment,
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      else
        @report.run_and_update!(@report.period_start, @report.period_end)
        flash[:download] =  "Your custom report has been created. #{view_context.link_to 'Download', stats_download_custom_report_path(id: @report.id)}"
        redirect_to stats_custom_path
      end
    else
      if create_custom_params[:correspondence_type].blank?
        @report.errors.add(:correspondence_type, :blank)
        @report.errors.delete(:report_type_id)
      end
      set_fields_for_custom_action
      render :custom
    end
  end

  def download_custom_report
    report= Report.find(params[:id])
    filename = report.report_type.filename('csv')

    send_data report.report_data, {filename: filename, disposition: :attachment}
  end

  private

  # The plan here is/was to colour the spreadsheet titles just like the existing reports from ITG
  LIGHT_BLUE = 'c1d1f0'
  LIGHT_GREY = 'd1d1e0'

  BRIGHT_RED = 'FF0000'
  BRIGHT_YELLOW = 'FFFF00'
  BRIGHT_LIME_GREEN = '00FF00'

  # mapping of RAG ratings to spreadsheet cell colours
  RAG_RATING_COLOURS = { red: BRIGHT_RED, amber: BRIGHT_YELLOW, green: BRIGHT_LIME_GREEN }

  # Assumes no report spans more than 26 columns
  SPREADSHEET_COLUMN_NAMES = ('A'..'Z').to_a

  def create_spreadsheet(report_data)
    axlsx = Axlsx::Package.new
    axlsx.workbook.add_worksheet do |sheet|
      report_data.to_csv.each_with_index do |row, row_index|
        # data is in the 'value' property of the cells
        sheet.add_row row.map(&:value)

        row.each_with_index do |item, item_index|
          if item.rag_rating
            cell_letter = SPREADSHEET_COLUMN_NAMES.fetch(item_index)
            cell = "#{cell_letter}#{row_index+1}"
            sheet.add_style cell, bg_color: RAG_RATING_COLOURS.fetch(item.rag_rating)
          end
        end
      end
    end
    axlsx
  end

  def set_fields_for_custom_action
    @custom_reports_foi = ReportType.custom.foi
    @custom_reports_sar = ReportType.custom.sar
    @correspondence_types = CorrespondenceType.by_report_category
  end

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
