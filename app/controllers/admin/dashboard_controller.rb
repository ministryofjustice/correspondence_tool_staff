class Admin::DashboardController < AdminController
  attr_reader :queries

  def feedback
    @feedbacks = Feedback.order(id: :desc).limit(20)
  end

  def exception
    raise 'Intentionally raised exception'
  end

  def search_queries
    @queries = SearchQuery.where(query_type: 'search').where(parent_id: nil).order(id: :desc).includes(:user).limit(100).decorate
  end

  def list_queries
    @queries = SearchQuery
                 .roots
                 .list
                 .order(id: :desc)
                 .includes(:user)
                 .limit(100)
                 .decorate
  end

  private

  def count_cases_created_on(date)
    Case::Base.where(created_at:  date.beginning_of_day..date.end_of_day).count
  end
end
