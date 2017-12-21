
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
    report_record = Report.create! report_type_abbr: report_abbr
    report_record.run(*args)
    report_record.trim_older_reports
  end
end
