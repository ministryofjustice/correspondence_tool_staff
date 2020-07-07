require 'csv'

module Stats
  module ETL
    class ClosedCases
      attr_reader :results_filepath, :retrieval_scope

      ROWS_PER_FRAGMENT = 1000 # Arbitrary value, may require experimentation
      RESULTS_NAME = 'closed-cases'.freeze

      # +retrieval_scope+ : ActiveQuery relation which Query::CaseReport
      # will use to ensure Warehouse retrieval is scoped for the current
      # requesting user
      def initialize(retrieval_scope:)
        @retrieval_scope = retrieval_scope
        @current_fragment_num = 0

        self
          .extract
          .transform
          .load
      end

      def extract
        # We use `@_temp_files` to prevent the Temp files being cleared
        # by ruby GC before they have been fully processed. In EC2 instances
        # this happens rapidly. Manual clearup/purge required as a result.
        #
        # Ordering of generation matters, each function call creates a temp CSV
        @_temp_files = generate_header_fragment + generate_data_fragments
        self
      end

      def transform
        self
      end

      def load
        commands = [
          "cd #{folder}",
          "cat *.csv > #{RESULTS_NAME}.csv",
          "zip #{RESULTS_NAME}.zip #{RESULTS_NAME}.csv"
        ].join('; ')

        if system(commands)
          @results_filepath = "#{folder}/#{filename}"
        end

        self
      end

      def filename
        RESULTS_NAME + '.zip'
      end


      private

      def columns
        @_columns ||= begin
          CSVExporter::CSV_COLUMN_HEADINGS.map { |f| f.parameterize.underscore }
        end
      end

      def heading
        @_heading ||= begin
          CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS, force_quotes: true)
        end
      end

      def folder
        @_folder ||= begin
          path = "#{Dir.tmpdir}/cts-reports/#{SecureRandom.uuid}"
          FileUtils.mkdir_p(path).first
        end
      end

      def num_fragments
        @_num_fragments ||= begin
          (@retrieval_scope.size.to_f/ROWS_PER_FRAGMENT).ceil
        end
      end

      def new_fragment(data)
        filename = "#{'%02d' % @current_fragment_num}-fragment-"
        @current_fragment_num += 1

        file = Tempfile.new([filename, '.csv'], folder)
        file.write(data)
        file.close
        file
      end

      def generate_header_fragment
        [new_fragment(heading)]
      end

      def generate_data_fragments
        offset = 0

        (1..num_fragments).map do |_i|
          data = CSV.generate(force_quotes: true) do |csv|
            Query::CaseReport.new(
              retrieval_scope: @retrieval_scope,
              columns: columns,
              offset: offset,
              limit: ROWS_PER_FRAGMENT
            ).execute { |row| csv << row }

            offset += ROWS_PER_FRAGMENT
          end

          new_fragment(data)
        end
      end
    end
  end
end
