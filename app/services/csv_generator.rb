require "csv"

# This will be the default lazy generator for case csv
# Lazy generation of CSV data so that we don't fill up memory when downloading
class CSVGenerator
  include Enumerable

  def initialize(cases, case_csv_exporter)
    @kases = cases
    @kase_csv_exporter = case_csv_exporter
  end

  def each
    columns = @kase_csv_exporter.class::CSV_COLUMN_HEADINGS

    yield CSV.generate_line columns
    @kases.each do |kase|
      yield CSV.generate_line @kase_csv_exporter.analyse_case(kase)
    end
  end

  class << self
    def filename(action_string)
      "#{action_string}-cases-#{Time.zone.now.strftime('%y-%m-%d-%H%M%S')}.csv"
    end
  end
end
