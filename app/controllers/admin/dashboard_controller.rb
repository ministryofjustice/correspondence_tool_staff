class Admin::DashboardController < AdminController
  attr_reader :queries

  def feedback
    @feedback_years = Feedback.group("to_char(created_at, 'yyyy')").count.sort.reverse
  end

  def feedback_year
    @feedbacks = Feedback.by_year(params[:year]).order(id: :desc)
  end

  def exception
    raise "Intentionally raised exception"
  end

  def search_queries
    @queries = SearchQuery.where(query_type: "search").where(parent_id: nil).order(id: :desc).includes(:user).limit(100).decorate
  end

  def list_queries
    @queries = SearchQuery
                 .roots
                 .list_query_type
                 .order(id: :desc)
                 .includes(:user)
                 .limit(100)
                 .decorate
  end

  def system
    @version = Settings.git_commit
  end

  def bank_holidays
    @bank_holidays = BankHoliday.order(created_at: :desc).page(params[:page]).per(50)
  end

  def load_bank_holidays
    BankHolidaysService.new
    flash[:notice] = "Bank holidays loaded successfully."
  rescue StandardError => e
    flash[:alert] = "Failed to load bank holidays: #{e.message}"
  ensure
    redirect_to admin_dashboard_bank_holidays_path
  end

  def personal_information_requests
    @personal_information_requests = PersonalInformationRequest
                                      .unscoped
                                      .order(created_at: :desc)
                                      .limit(500)
  end

  def events
    @events = Rails.configuration.event_store
      .read
      .backward
      .newer_than_or_equal(30.days.ago)
      .to_a
      .map { |event| SystemLogEventPresenter.new(event) }

    @email_failed_events_count = @events.count(&:email_failed_event?)
    @rpi_failed_events_count = @events.count(&:rpi_failed_event?)
  end

private

  def count_cases_created_on(date)
    Case::Base.where(created_at: date.all_day).count
  end
end
