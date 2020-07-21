class ReportPolicy < ApplicationPolicy
  attr_reader :user, :report

  def initialize(user, report)
    @report = report
    super(user, report)
  end

  def can_download_user_generated_report?
    clear_failed_checks

    if !report.user_id.nil?
      report.user_id == user.id
    else
      true
    end
  end
end
