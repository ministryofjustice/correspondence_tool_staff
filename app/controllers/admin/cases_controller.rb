class Admin::CasesController < AdminController
  def index
    @dates = {}
    5.times do |n|
      date = n.business_days.ago.to_date
      @dates[date] = count_cases_created_on(date)
    end
    @cases = Case::Base.all.order(id: :desc).page(params[:page]).decorate
  end

private

  def count_cases_created_on(date)
    Case::Base.where(created_at: date.all_day).count
  end
end
