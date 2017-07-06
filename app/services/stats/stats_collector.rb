require 'csv'

module Stats

  # This class acts as a model to collect statistics in rows and columns for later outputting
  # to a CSV or spreadsheet
  class StatsCollector

    attr_reader :stats

    def initialize(rows, columns)
      @stats = {}
      rows.each do |row|
        @stats[row] = {}
        columns.each do |col|
          @stats[row][col] = 0
        end
      end
    end

    def record_stats(row, col, count = 1)
      raise ArgumentError.new("No such row name: '#{row}'") unless @stats.key?(row)
      raise ArgumentError.new("No such column name: '#{col}'") unless @stats[row].key?(col)
      @stats[row][col] += count
    end

    def row_names
      @stats.keys.sort
    end

    def column_names
      @stats[@stats.keys.first].keys.sort
    end

    def value(row, col)
      @stats[row][col]
    end

    def to_csv(first_column_header = '')
      cols = [first_column_header] + column_names
      CSV.generate(headers: true) do |csv|
        csv << cols
        row_names.each do |row_name|
          row = [row_name]
          column_names.each { |column_name| row << value(row_name, column_name) }
          csv << row
        end
      end
    end

  end
end
