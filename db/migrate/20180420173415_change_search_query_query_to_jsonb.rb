class ChangeSearchQueryQueryToJsonb < ActiveRecord::Migration[5.0]
  class SearchQueryMigration < ActiveRecord::Base
    self.table_name = :search_queries
  end

  def up
    SearchQueryMigration.transaction do
      SearchQueryMigration.all.each do |search_query|
        search_query.update_column(
          :query,
          "{\"search\": {\"query\":\"#{search_query.query}\"}}"
        )
      end

      change_column :search_queries, :query, :jsonb, using: 'query::jsonb'
    end
  end

  def down
    SearchQueryMigration.transaction do
      change_column :search_queries, :query, :string, null: false

      SearchQueryMigration.all.each do |search_query|
        search_query.update_column(
          :query,
          JSON.parse(search_query.query)['search']['query']
        )
      end
    end
  end
end
