require 'csv'

class CSVGenerator

  def initialize(kases)
    @kases = kases
  end

  def to_csv
    CSV.generate do |csv|
      csv << CSVExporter::CSV_COLUMN_HEADINGS
      @kases.each { |kase| csv << kase.to_csv }
    end
  end

  def self.options(action_string)
    {
        filename: "#{action_string}-cases-#{Time.now.strftime('%y-%m-%d-%H%M%S')}.csv",
        type: 'text/csv; charset=utf-8'
    }
  end

end
