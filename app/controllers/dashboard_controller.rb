class DashboardController < ApplicationController

  def cases
    @dates = { }
    5.times do |n|
      date = n.business_days.ago.to_date
      @dates[date] = count_cases_created_on(date)
    end
  end

  def feedback
    @feedbacks = Feedback.order(id: :desc).limit(20)
  end



  private

  def count_cases_created_on(date)
    Case.where(created_at:  date.beginning_of_day..date.end_of_day).count
  end

end
