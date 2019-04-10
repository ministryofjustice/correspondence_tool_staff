require 'csv'

# Lazy generation of CSV data so that we don't fill up memory when downloading
class CSVGenerator
  include Enumerable

  def initialize(kases)
    @kases = kases
  end

  def each
    yield CSV.generate_line CSVExporter::CSV_COLUMN_HEADINGS
    @kases.each do |kase|
      yield CSV.generate_line kase.to_csv
    end
  end

  class << self
    def filename(action_string)
      "#{action_string}-cases-#{Time.now.strftime('%y-%m-%d-%H%M%S')}.csv"
    end
  end
end
