module Query
  class CaseReport
    attr_reader :columns, :limit, :offset, :retrieval_scope

    def initialize(retrieval_scope:, columns: ["*"], offset: nil, limit: nil)
      @retrieval_scope = retrieval_scope
      @columns = columns
      @offset = offset
      @limit = limit
      @connection = ActiveRecord::Base.connection.instance_variable_get(:@connection)
    end

    def execute(&block)
      @connection.send_query(query)
      @connection.set_single_row_mode

      loop do
        results = @connection.get_result or break

        results.check
        results.stream_each_row(&block)
      end
    end

    def query
      warehouse = ::Warehouse::CaseReport.table_name
      limit = []
      limit << "OFFSET #{@offset}" if @offset.present?
      limit << "LIMIT #{@limit}" if @limit.present?

      <<~SQL.squish
        WITH retrieved_cases AS (#{@retrieval_scope.select(:id).to_sql} #{limit.join(' ')})#{'        '}
        SELECT#{' '}
          #{@columns.join(', ').chomp(',')}
        FROM#{' '}
          #{warehouse}
        INNER JOIN
          retrieved_cases
        ON#{' '}
          retrieved_cases.id = #{warehouse}.case_id
      SQL
    end
  end
end
