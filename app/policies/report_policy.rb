class ReportPolicy < ApplicationPolicy
  attr_reader :user, :report

  def initialize(user, report)
    @report = report
    super(user, report)
  end

  def can_download_user_generated_report?
    clear_failed_checks

    begin
      info = JSON.parse(report.report_data, symbolize_names: true)
      info[:user_id] == user.id
    end
    rescue JSON::ParserError
      true
    end
  end
end
