require 'csv'

module Stats

  # This class acts as a model to collect statistics in rows and columns for later outputting
  # to a CSV or spreadsheet
  class StatsCollector

    attr_reader :stats

    # intitialize with an array of row names, and a hash of column headings keyed by unique identifier
    def initialize(rows, columns)
      @column_hash = columns
      @stats = {}
      rows.each do |row|
        @stats[row] = {}
        @column_hash.keys.each do |col_key|
          @stats[row][col_key] = 0
        end
      end
    end

    def record_stats(row, col_key, count = 1)
      raise ArgumentError.new("No such row name: '#{row}'") unless @stats.key?(row)
      raise ArgumentError.new("No such column name: '#{col_key}'") unless @stats[row].key?(col_key)
      @stats[row][col_key] += count
    end

    def row_names
      @stats.keys.sort
    end

    def column_names
      @column_hash.values
    end

    def value(row, col)
      @stats[row][col]
    end

    def to_csv(first_column_header = '', superheadings = [Array.new])
      cols = [first_column_header] + column_names
      x = CSV.generate(headers: true) do |csv|
        superheadings.each { |superheading| csv << superheading }
        csv << cols
        row_names.each do |row_name|
          row = [row_name]
          # @column_hash.each { | col_key, col_hdg| row << value(row_name, col_key) }
          @column_hash.keys.each { |col_key| row << value(row_name, col_key) }
          csv << row
        end
      end
      x
    end

  end
end
