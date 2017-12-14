
# see https://github.com/moove-it/sidekiq-scheduler
#
#
#
require 'sidekiq-scheduler'

class ReportGeneratorJob < ApplicationJob

  queue_as :report_generator

  def perform(report_abbr, *args)
    Rails.logger.info "generating report #{report_abbr}"
    RavenContextProvider.set_context
    report_type = ReportType.find_by_abbr(report_abbr)
    report_record = Report.create!(
      report_type_id: report_type.id,
      period_start: nil,
      period_end: nil
    )

    report_klass = report_type.class_name.constantize
    report = args.empty? ? report_klass.new : report_klass.new(*args)
    report.run

    report_record.update(report_data: report.to_csv,
                         period_start: report.period_start,
                         period_end: report.period_end)
    report_record.save!
  end
end
