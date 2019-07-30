module Query
  class ClosedCases
    attr_reader :limit, :offset

    def initialize(offset: nil, limit: nil)
      @offset = offset
      @limit = limit
      @connection = ActiveRecord::Base.connection.instance_variable_get(:@connection)
    end

    def execute
      @connection.send_query(query)
      @connection.set_single_row_mode

      loop do
        results = @connection.get_result or break

        results.check
        results.stream_each_row do |row|
          yield(row)
        end
      end
    end

    def query
      limit = []
      limit << "OFFSET #{@offset}" if @offset.present?
      limit << "LIMIT #{@limit}" if @limit.present?

      <<~SQL
        SELECT 
          *
        FROM 
          #{Warehouse::CasesReport.table_name}

        #{limit.join(' ')}
     SQL
    end
  end
end
