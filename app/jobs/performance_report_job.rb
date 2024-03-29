class PerformanceReportJob < ApplicationJob
  queue_as :performance_report

  def perform(report_service_class_name, report_job_guid, period_start_ts, period_end_ts, offset)
    SentryContextProvider.set_context
    begin
      report_service_class = report_service_class_name.constantize
      report_service = report_service_class.new(
        period_start: Time.zone.at(period_start_ts).to_date,
        period_end: Time.zone.at(period_end_ts).to_date,
      )
      report_service.process(offset, report_job_guid:)
    rescue NameError => e
      Rails.logger.error "#{report_service_class_name}: #{e.class} - #{e.message}"
    end
  end
end
