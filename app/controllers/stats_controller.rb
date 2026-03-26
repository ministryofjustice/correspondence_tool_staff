require "csv"

class StatsController < ApplicationController
  # @note (Mohammed Seedat): Interim solution to allow 'Closed Cases'
  #   to be considered a custom reporting option
  FauxCorrespondenceType = Struct.new(:abbreviation, :report_category_name)

  before_action :authorize_user

  SPREADSHEET_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  def index
    @reports = Pundit.policy_scope(current_user, ReportType.where(standard_report: true).all)
  end

  def show
    report = Report.new report_type_id: params[:id]

    report.run_and_update!(user: current_user)
    if report.background_job?
      # should display the link for downloading
      flash[:download] = report_download_link(report.id, "success")
      redirect_back(fallback_location: root_path)
    else
      generate_final_report(report)
    end
  end

  def new
    @report = Report.new
    set_fields_for_custom_action
  end

  def create
    @report = Report.new(create_custom_params)

    if @report.valid?
      @report.run_and_update!(
        user: current_user,
        period_start: @report.period_start,
        period_end: @report.period_end,
      )
      if @report.background_job? || @report.persist_results?
        flash[:download] = report_download_link(@report.id, "success")
        redirect_to new_stat_path
      else
        generate_final_report(@report)
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
    report_data, = report.report_details
    if report.background_job?
      return download_waiting(report) unless report.ready?

      authorize report, :can_download_user_generated_report?
    end

    generate_final_report(report, report_data)
  end

  def download_audit
    report = Stats::R900AuditReport.new
    report.run_and_update!
    send_data generate_csv(report.report_data), filename: "R900Audit.csv"
  end

  def self.closed_cases_correspondence_type
    FauxCorrespondenceType.new("CLOSED_CASES", "General closed cases report")
  end

private

  def send_xlsx_report(report)
    axlsx = create_spreadsheet(report)

    send_data axlsx.to_stream.read,
              filename: report.filename,
              disposition: :attachment,
              type: SPREADSHEET_CONTENT_TYPE
  end

  def send_csv_report(report)
    send_data generate_csv(report),
              filename: report.filename,
              disposition: :attachment
  end

  def send_default_report(report, report_data = nil)
    # If the data is relevant big, it will be passed as report data, otherwise the data will
    # be stored in report record
    report_data_for_generation = report_data || report.report_data
    send_data report_data_for_generation,
              filename: report.filename,
              disposition: :attachment
  end

  def generate_final_report(report, report_data = nil)
    case report.report_format
    when "xlsx"
      send_xlsx_report(report)
    when "csv"
      send_csv_report(report)
    else
      send_default_report(report, report_data)
    end
  end

  def generate_csv(report)
    # Force quotes to prevent jagged rows in CSVs
    CSV.generate(headers: true, force_quotes: true) do |csv_generator|
      report.to_csv.each do |csv_row|
        csv_generator << csv_row.map(&:value)
      end
    end
  end

  # The plan here is/was to colour the spreadsheet titles just like the existing reports from ITG
  LIGHT_BLUE = "c1d1f0".freeze
  LIGHT_GREY = "d1d1e0".freeze

  BRIGHT_RED = "FF0000".freeze
  BRIGHT_YELLOW = "FFFF00".freeze
  BRIGHT_LIME_GREEN = "00FF00".freeze

  # mapping of RAG ratings to spreadsheet cell colours
  RAG_RATING_COLOURS = { red: BRIGHT_RED,
                         amber: BRIGHT_YELLOW,
                         green: BRIGHT_LIME_GREEN,
                         grey: LIGHT_GREY,
                         blue: LIGHT_BLUE }.freeze

  # Assumes no report spans more than 30 columns
  SPREADSHEET_COLUMN_NAMES = (("A".."Z").to_a + %w[AA AB AC AD]).freeze

  def create_spreadsheet(report)
    axlsx = Axlsx::Package.new
    axlsx.workbook.add_worksheet do |sheet|
      report.to_csv.each_with_index do |row, row_index|
        # data is in the 'value' property of the cells
        sheet.add_row row.map(&:value)

        row.each_with_index do |item, item_index|
          next unless item.rag_rating

          cell_letter = SPREADSHEET_COLUMN_NAMES.fetch(item_index)
          cell = "#{cell_letter}#{row_index + 1}"
          sheet.add_style cell, bg_color: RAG_RATING_COLOURS.fetch(item.rag_rating)
        end
      end
    end
    axlsx
  end

  def is_general_closed_report_present?
    Pundit.policy_scope(current_user, ReportType.closed_cases_report).present?
  end

  def user_permitted_custom_report_types
    # find out the scope of the custom report types the user can see via set intersection operation
    @correspondence_types = CorrespondenceType.custom_reporting_types & current_user.permitted_correspondence_types
    if is_general_closed_report_present?
      @correspondence_types << self.class.closed_cases_correspondence_type
    end
  end

  def set_fields_for_custom_action
    @custom_reports_foi = ReportType.custom.foi
    @custom_reports_sar = ReportType.custom.sar
    @custom_reports_offender_sar = ReportType.custom.offender_sar
    @custom_reports_offender_sar_complaint = ReportType.custom.offender_sar_complaint
    @custom_reports_closed_cases = ReportType.closed_cases_report
    user_permitted_custom_report_types
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
        :period_end_dd, :period_end_mm, :period_end_yyyy
      )
  end

  def report_download_link(report_id, translation_key)
    [
      t(".#{translation_key}"),
      view_context.link_to(
        "Download",
        download_custom_stats_path(id: report_id),
      ),
    ].join(" ")
  end

  def download_waiting(report)
    flash[:download] = report_download_link(report.id, "waiting")
    @report = report
    set_fields_for_custom_action

    render :new
  end
end
