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

  def personal_information_requests
    @personal_information_requests = PersonalInformationRequest
                                      .unscoped
                                      .order(created_at: :desc)
                                      .limit(500)
  end

  def system_logs
    @system_logs = SystemLog.recent
  end

  def email_logs
    @email_logs = EmailLog.recent
  end

private

  def count_cases_created_on(date)
    Case::Base.where(created_at: date.all_day).count
  end
end
