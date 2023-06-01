require 'csv'

module Stats

  # This class acts as a model to collect statistics in rows and columns for later outputting
  # to a CSV or spreadsheet
  class StatsCollector

    attr_accessor :stats

    # intitialize with an array of row names, and a hash of column headings keyed by unique identifier
    # row names that begin with an underscore have special meaning:
    # If they begin _SPACER, then nothing will be printed on that line
    # Anything else beginning with an underscore, will be treated as a section heading and printed without the underscore
    def initialize(rows, columns)
      @column_hash = columns
      @callback_methods = {
        before_finalise: []
      }
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

    def add_callback(callback_type, meth)
      raise "Invalid callback type " unless callback_type.in?(@callback_methods.keys)
      @callback_methods[callback_type] << meth
    end

    def record_stats(row, col, count = 1)
      check_row_and_col_exist(row, col)
      @stats[row][col] += count
    end

    # finalize() will run any :before_finalise callback methods that have been registered with add_callback()
    def finalise
      @callback_methods[:before_finalise].each do |meth|
        meth.call
      end
    end

    def record_text(row, col, text)
      check_row_and_col_exist(row, col)
      @stats[row][col] = text
    end

    def check_row_and_col_exist(row, col)
      raise ArgumentError.new("No such row name: '#{row}'") unless @stats.key?(row)
      raise ArgumentError.new("No such column name: '#{col.inspect}'") unless @stats[row].key?(col)
    end

    class StatsEnumerator
      include Enumerable

      def initialize(stats, column_hash, first_column_header, superheadings, row_names_as_first_column)
        @stats = stats
        @column_hash = column_hash
        @first_column_header = first_column_header
        @superheadings = superheadings
        @row_names_as_first_column = row_names_as_first_column
      end

      # This is a lazy enumerator for each of the rows in the report.
      # so that we don't sit and timeout the browser waiting to fetch all
      # the rows from the database in a big report.
      def each #rubocop:disable Metrics/CyclomaticComplexity
        cols = column_names
        cols.unshift @first_column_header if @row_names_as_first_column
        @superheadings.each { |superheading| yield superheading }
        yield cols
        row_names.each do |row_name|
          row_name_str = row_name.to_s
          if row_name_str =~ /^_SPACER/
            row = ['']
          elsif row_name_str =~ /^_/
            row = [row_name_str.sub(/^_/, '')]
          else
            row = @row_names_as_first_column ? [row_name_str] : []
            @column_hash.keys.each { |col_key| row << value(row_name, col_key) }
          end
          yield row
        end
      end

      def column_names
        @column_hash.values
      end

      def row_names
        @stats.keys
      end

      def value(row, col)
        @stats[row][col]
      end
    end

    def to_csv(first_column_header: '', superheadings: [], row_names_as_first_column: true)
      StatsEnumerator.new(@stats, @column_hash, first_column_header, superheadings, row_names_as_first_column)
    end

    private

    def spacer_or_section_header?(row)
      row.to_s =~ /^_/
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
