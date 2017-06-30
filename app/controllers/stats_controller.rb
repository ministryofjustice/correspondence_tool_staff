class StatsController < ApplicationController

  def index
    authorize Case.first, :can_download_stats?
  end

  def download
    authorize Case.first, :can_download_stats?

    filename = "correspondence-tool-#{Date.today}.csv"
    report = Stats::R001RespondedCaseTimelinessReport.new
    report.run

    send_data report.to_csv, filename: filename
    flash[:notice] = "CSV file has been downloaded with name #{filename}"
  end
end

