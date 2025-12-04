class BankHolidaysController < ApplicationController
  # GET /bank_holidays
  def index
    @bank_holidays = BankHoliday.all
    render json: @bank_holidays
  end

  # Optional: endpoint to trigger API refresh (secure this for admin use only)
  def refresh
    BankHolidayImporter.import!
    render json: { status: "imported" }
  end
end
