class DashboardController < ActionController::Base

  def cases
    @dates = { }
    5.times do |n|
      date = n.business_days.ago.to_date
      @dates[date] = count_cases_received_on(date)
    end
  end

  def feedback
    @feedbacks = Feedback.order(:id)
  end



  private

  def count_cases_received_on(date)
    Case.where('received_date BETWEEN ? and ?', date.beginning_of_day, date.end_of_day).count
  end

end
