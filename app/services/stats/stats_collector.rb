require 'csv'

module Stats

  # This class acts as a model to collect statistics in rows and columns for later outputting
  # to a CSV or spreadsheet
  class StatsCollector

    attr_reader :stats

    # intitialize with an array of row names, and a hash of column headings keyed by unique identifier
    # row names that begin with an underscore have special meaning:
    # If they begin _SPACER, then nothing will be printed on that line
    # Anything else beginning with an underscore, will be treated as a section heading and printed without the underscore
    def initialize(rows, columns)
      @column_hash = columns
      @stats = {}
      rows.each do |row|
        @stats[row] = {}
        if spacer_or_section_header?(row)
          populate_spacer_or_section_header_row(row)
        else
          populate_value_row(row)
        end
      end
    end

    def record_stats(row, col, count = 1)
      check_row_and_col_exist(row, col)
      @stats[row][col] += count
    end

    def record_text(row, col, text)
      check_row_and_col_exist(row, col)
      @stats[row][col] = text
    end

    def check_row_and_col_exist(row, col)
      raise ArgumentError.new("No such row name: '#{row}'") unless @stats.key?(row)
      raise ArgumentError.new("No such column name: '#{col.inspect}'") unless @stats[row].key?(col)
    end

    def to_csv(first_column_header = '', superheadings = [Array.new])
      cols = [first_column_header] + column_names
      CSV.generate(headers: true) do |csv|
        superheadings.each { |superheading| csv << superheading }
        csv << cols
        row_names.each do |row_name|
          if row_name =~ /^_SPACER/
            row = ['']
          elsif row_name =~ /^_/
            row = [row_name.sub(/^_/, '')]
          else
            row = [row_name]
            @column_hash.keys.each { |col_key| row << value(row_name, col_key) }
          end
          csv << row
        end
      end
    end

    def row_names
      @stats.keys
    end

    def column_names
      @column_hash.values
    end

    def value(row, col)
      @stats[row][col]
    end

    private

    def spacer_or_section_header?(row)
      row =~ /^_/
    end

    def populate_spacer_or_section_header_row(row)
      @stats[row] = ''
    end

    def populate_value_row(row)
      @column_hash.keys.each do |col_key|
        @stats[row][col_key] = 0
      end
    end

  end
end
