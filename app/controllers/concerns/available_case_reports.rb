module AvailableCaseReports
  extend ActiveSupport::Concern
  included do
    before_action -> { get_available_reports }
  end

private

  def get_available_reports
    @available_reports = if current_user
                           Pundit.policy_scope(current_user, get_cases_reports)
                         else
                           []
                         end
  end

  def get_cases_reports
    ReportType.where("abbr like ? ", "R90%").all
  end
end
