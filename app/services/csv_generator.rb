require 'csv'

# This will be the default lazy generator for case csv
# Lazy generation of CSV data so that we don't fill up memory when downloading
class CSVGenerator
  include Enumerable

  def initialize(cases, case_csv_exporter=nil)
    @kases = cases
    @kase_csv_exporter = case_csv_exporter
  end

  def each
    if @kase_csv_exporter
      columns = @kase_csv_exporter.class::COLUMN_HEADINGS
    else
      columns = CSVExporter::CSV_COLUMN_HEADINGS
    end 

    yield CSV.generate_line columns
    @kases.each do |kase|
      if @kase_csv_exporter
        yield CSV.generate_line @kase_csv_exporter.analyse_case(kase)
      else
        yield CSV.generate_line kase.to_csv
      end 
    end
  end

  class << self
    def filename(action_string)
      "#{action_string}-cases-#{Time.now.strftime('%y-%m-%d-%H%M%S')}.csv"
    end
  end
end
