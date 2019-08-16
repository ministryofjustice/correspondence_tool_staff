require 'csv'

module Stats
  module ETL
    class ClosedCases
      attr_reader :results_filepath, :retrieval_scope

      ROWS_PER_FRAGMENT = 1000 # Arbitrary value, may require experimentation
      RESULTS_NAME = 'closed-cases'.freeze

      # +retrieval_scope+ : ActiveQuery relation which Query::ClosedCases
      # will use to ensure Warehouse retrieval is scoped for the current
      # requesting user
      def initialize(retrieval_scope:)
        @retrieval_scope = retrieval_scope

        self
          .extract
          .transform
          .load
      end

      def extract
        offset = 0

        # We use `@_temp_files` to prevent the Temp files being cleared
        # by ruby GC before they have been fully processed. In EC2 instances
        # this happens rapidly. Manual clearup/purge required as a result
        @_temp_files =
          # 0. Header
          [new_fragment("fragment_00_header_", heading)] +

          # 1. Rest of the CSV rows
          (1..num_fragments + 1).map do |fragment_num|
            data = CSV.generate(force_quotes: true) do |csv|
              Query::ClosedCases.new(
                retrieval_scope: @retrieval_scope,
                columns: columns,
                offset: offset,
                limit: ROWS_PER_FRAGMENT
              )
              .execute { |row| csv << row }

              offset += ROWS_PER_FRAGMENT
            end

            new_fragment("fragment_#{'%02d' % fragment_num}_", data)
          end

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
          CSVExporter::CSV_COLUMN_HEADINGS.join(',').chomp(',')
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
          (::Warehouse::CaseReport.all.size.to_f/ROWS_PER_FRAGMENT).ceil
        end
      end

      def new_fragment(filename, data)
        file = Tempfile.new([filename, '.csv'], folder)
        file.write(data)
        file.close
        file
      end
    end
  end
end
