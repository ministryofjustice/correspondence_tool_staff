class PerformanceReportJob < ApplicationJob

    queue_as :performance_report
  
    def perform(report_service_string, report_job_guid, period_start_ts, period_end_ts, offset)
        RavenContextProvider.set_context
        
        report_service_class = report_service_string.constantize
        report_service = report_service_class.new(
            period_start: Time.at(period_start_ts).to_date,
            period_end: Time.at(period_end_ts).to_date  
        )
        report_service.process(offset, report_job_guid)
    end
end
