module AvailableCaseReports
  extend ActiveSupport::Concern
  included do
    before_action -> { get_available_reports }
  end

  private 

  def get_available_reports
    if current_user
      @available_reports = Pundit.policy_scope(current_user, get_cases_reports)
    else
      @available_reports = []
    end
  end 

  def get_cases_reports
    ReportType.where("abbr like ? ", "R90%").all
  end

end
