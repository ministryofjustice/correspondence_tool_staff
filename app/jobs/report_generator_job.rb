
# see https://github.com/moove-it/sidekiq-scheduler
#

class ReportGeneratorJob < ApplicationJob

  queue_as :report_generator

  def perform(report_abbr, *args)
    RavenContextProvider.set_context
    report_type = ReportType.find_by_abbr(report_abbr)
    report_record = Report.create!(
      report_type_id: report_type.id,
      period_start: nil,
      period_end: nil
    )

    report_klass = report_type.class_name.constantize

    report = report_klass.new(args)
    report_record.report_data = report.to_csv
    report.save!
  end
end
