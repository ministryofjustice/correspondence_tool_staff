class RemoveSearchQueryListParams < ActiveRecord::Migration[5.0]
  def up
    execute <<~EOSQL
      UPDATE search_queries SET query=query - 'list_params';
    EOSQL
  end

  def down
    open_in_time_params = '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\ncontroller: cases\naction: open_cases\ntab: in_time\n'
    open_late_params = '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\ncontroller: cases\naction: open_cases\ntab: late\n'

    execute <<~EOSQL
      UPDATE search_queries
             SET query=query || '{"list_params": "#{open_in_time_params}"}'
             WHERE query->>'list_path' = '/cases/open/in_time';
    EOSQL

    execute <<~EOSQL
      UPDATE search_queries
             SET query=query || '{"list_params": "#{open_late_params}"}'
             WHERE query->>'list_path' = '/cases/open/late';
    EOSQL
  end
end
