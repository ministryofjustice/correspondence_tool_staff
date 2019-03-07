require 'csv'

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

    def type
      'text/csv; charset=utf-8'
    end

    def options(action_string)
      {
        filename: self.filename(action_string),
        type: self.type
      }
    end
  end
end
