require 'csv'
require 'tempfile'

class StatsController < ApplicationController
  # @note (Mohammed Seedat): Interim solution to allow 'Closed Cases'
  #   to be considered a custom reporting option
  FauxCorrespondenceType = Struct.new(:abbreviation, :report_category_name)

  before_action :authorize_user

  SPREADSHEET_CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.freeze

  def index
    @foi_reports = ReportType.standard.foi.order(:full_name)
    @sar_reports = ReportType.standard.sar.order(:full_name)
  end

  def show
    report = Report.new report_type_id: params[:id]

    if report.xlsx?
      report_data = report.run

      axlsx = create_spreadsheet(report_data)

      send_data axlsx.to_stream.read,
                filename: report.report_type.filename('xlsx'),
                disposition: :attachment,
                type: SPREADSHEET_CONTENT_TYPE
    else
      report.run_and_update!(user: current_user)
      send_data report.report_data, filename: report.report_type.filename('csv')
    end
  end

  def new
    @report = Report.new
    set_fields_for_custom_action
  end

  def create
    @report = Report.new(create_custom_params)

    if @report.valid?
      if @report.xlsx?
        generate_custom_excel_report(@report)
      else
        generate_custom_csv_report(@report)
      end
    else
      if create_custom_params[:correspondence_type].blank?
        @report.errors.add(:correspondence_type, :blank)
        @report.errors.delete(:report_type_id)
      end

      set_fields_for_custom_action

      render :new
    end
  end

  def download_custom
    report = Report.find(params[:id])
    data, filename = report.report_details

    if report.report_type.etl?
      return download_waiting(report) unless report.etl_ready?
      authorize report, :can_download_user_generated_report?
    end

    send_data data, {
      filename: filename,
      disposition: :attachment
    }
  end

  def download_audit
    report = Stats::R900AuditReport.new
    report.run_and_update!
    send_data report.report_data, filename: "R900Audit.csv"
  end

  def self.closed_cases_correspondence_type
    FauxCorrespondenceType.new('CLOSED_CASES', 'Closed cases report')
  end


  private

  # The plan here is/was to colour the spreadsheet titles just like the existing reports from ITG
  LIGHT_BLUE = 'c1d1f0'
  LIGHT_GREY = 'd1d1e0'

  BRIGHT_RED = 'FF0000'
  BRIGHT_YELLOW = 'FFFF00'
  BRIGHT_LIME_GREEN = '00FF00'

  # mapping of RAG ratings to spreadsheet cell colours
  RAG_RATING_COLOURS = { red: BRIGHT_RED,
                         amber: BRIGHT_YELLOW,
                         green: BRIGHT_LIME_GREEN,
                         grey: LIGHT_GREY,
                         blue: LIGHT_BLUE }

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
    @custom_reports_closed_cases = ReportType.closed_cases_report
    @correspondence_types = CorrespondenceType.custom_reporting_types +
      [self.class.closed_cases_correspondence_type]
  end

  def authorize_user
    authorize Case::Base, :can_download_stats?
  end

  def create_custom_params
    params
      .require(:report)
      .permit(
        :correspondence_type,
        :report_type_id,
        :period_start_dd, :period_start_mm, :period_start_yyyy,
        :period_end_dd, :period_end_mm, :period_end_yyyy,
      )
  end

  def generate_custom_excel_report(report)
    report_data = report.run(
      period_start: report.period_start,
      period_end: report.period_end
    )

    send_data(
      create_spreadsheet(report_data).to_stream.read,
      filename: report.report_type.filename('xlsx'),
      disposition: :attachment,
      type: SPREADSHEET_CONTENT_TYPE
    )
  end

  def generate_custom_csv_report(report)
    report.run_and_update!(
      user: current_user,
      period_start: report.period_start,
      period_end: report.period_end
    )

    if report.immediate_download?
      send_data(
        report.report_data,
        filename: report.report_type.filename('csv')
      )
    else
      flash[:download] = report_download_link(report.id, 'success')
      redirect_to new_stat_path
    end
  end

  def report_download_link(report_id, translation_key)
    [
      t(".#{translation_key}"),
      view_context.link_to(
        'Download',
        download_custom_stats_path(id: report_id)
      ),
    ].join(' ')
  end

  def download_waiting(report)
    flash[:download] = report_download_link(report.id, 'waiting')
    @report = report
    set_fields_for_custom_action

    render :new
  end
end
