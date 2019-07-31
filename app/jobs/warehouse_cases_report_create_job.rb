class WarehouseCasesReportCreateJob < ApplicationJob

  queue_as :warehouse

  def perform(user_id, period_start_ts, period_end_ts)
    puts "\nPERFORMING JOB__________________\n"
    period_start = Time.at(period_start_ts).to_date
    period_end = Time.at(period_end_ts).to_date
    user = User.find(user_id)
    scope = CaseFinderService.new(user).closed_cases_scope.where(received_date: [period_start..period_end]).order(received_date: :asc)
    etl = Stats::ETL::ClosedCases.new(retrieval_scope: scope)
    filepath = etl.results_filepath

    # NEED TO GET THE FILEPATH SAVED IN THE REPORTS TABLE!
    puts "\n\n\n\n=====> JOB: #{filepath.inspect}\n\n\n\n\n"
    #RavenContextProvider.set_context
    #etl = ETL::ClosedCases.new(retrieval_scope: scope)
    #@filepath = etl.results_filepath
  end
end
