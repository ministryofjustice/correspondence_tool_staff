require 'csv'

module Stats
  module ETL
    class ClosedCases
      attr_reader :results_filepath

      ROWS_PER_FRAGMENT = 1000
      RESULTS_NAME = 'closed-cases'

      def initialize
        self
          .extract
          .transform
          .load
      end

      def extract
        puts "Extract..."

        offset = 0
        # Generate Header first

        # We use `files` to prevent the Temp files being cleared
        # by ruby GC before they have been fully processed
        files = (0..num_fragments).map do |fragment_num|
          data = CSV.generate(force_quotes: true) do |csv|
            query = Query::ClosedCases.new(offset: offset, limit: ROWS_PER_FRAGMENT)
            query.execute do |row|
              csv << row
            end

            offset += ROWS_PER_FRAGMENT
          end

          new_fragment("fragment_#{fragment_num}_", data)
        end

        self
      end

      def transform
        puts "Transform..."

        self
      end

      def load
        puts "Load..."

        commands = [
          "cd #{folder}",
          "cat *.csv > #{RESULTS_NAME}.csv",
          "zip #{RESULTS_NAME}.zip #{RESULTS_NAME}.csv"
        ].join('; ')

        if system(commands)
          @results_filepath = "#{folder}/#{RESULTS_NAME}.zip"
          #system("cd #{folder_name}; rm *;")
        end

        self
      end


      private

      def folder
        @_folder ||= begin
          path = "#{Dir.tmpdir}/cts-reports/#{SecureRandom.uuid}"
          FileUtils.mkdir_p(path).first
        end
      end

      def num_fragments
        @_num_fragments ||= begin
          (Warehouse::CasesReport.all.size.to_f/ROWS_PER_FRAGMENT).round
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
