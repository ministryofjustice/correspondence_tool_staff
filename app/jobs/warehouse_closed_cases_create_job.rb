class WarehouseClosedCasesCreateJob < ApplicationJob

  queue_as :warehouse

  def perform(report_guid, user_id, period_start_ts, period_end_ts)
    Stats::R007ClosedCasesReport.process(
      report_guid: report_guid,
      user: User.find(user_id),
      period_start: Time.at(period_start_ts).to_date,
      period_end: Time.at(period_end_ts).to_date
    )
  end
end
