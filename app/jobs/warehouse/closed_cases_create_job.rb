module Warehouse
  class ClosedCasesCreateJob < ApplicationJob
    queue_as :reports

    # +period_start_ts+ and +period_end_ts+ are integer timestamps
    def perform(report_service_class_name, report_guid, user_id, period_start_ts, period_end_ts)
      SentryContextProvider.set_context

      begin
        report_service_class = report_service_class_name.constantize
        if report_service_class < Stats::BaseClosedCasesReport
          report_service = report_service_class.new(
            user: User.find(user_id),
            period_start: Time.zone.at(period_start_ts).to_date,
            period_end: Time.zone.at(period_end_ts).to_date,
          )

          report_service.process(report_guid:)
        else
          Rails.logger.error "#{report_service_class_name}: is not subclass of Stats::BaseClosedCasesReport"
        end
      rescue NameError => e
        Rails.logger.error "#{report_service_class_name}: #{e.class} - #{e.message}"
      end
    end
  end
end
